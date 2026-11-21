
import os
from functools import wraps
from pathlib import Path
from datetime import date
import firebase_admin
from firebase_admin import auth, credentials
from flask import Flask, jsonify, request
from sqlalchemy import text, select 
from sqlalchemy.exc import IntegrityError

from config import BASE_DIR, Config
from models import (
    db,
    Student,
    Wallet,
    WalletTransaction,
    SavingsAccount,
    SavingsTransaction,
    SavingsTransaction,
    Expense,
)

def initialize_firebase():
    """Initialize Firebase Admin for server-side token checks."""

    if firebase_admin._apps:
        return

    key_name = os.getenv(
        "FIREBASE_SERVICE_ACCOUNT",
        "serviceAccountKey.json",
    )

    key_path = Path(key_name)

    if not key_path.is_absolute():
        key_path = BASE_DIR / key_path

    if not key_path.is_file():
        raise RuntimeError(
            "Firebase service-account file was not found. "
            "Check FIREBASE_SERVICE_ACCOUNT in backend/.env."
        )

    credential = credentials.Certificate(str(key_path))

    firebase_admin.initialize_app(credential)


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)
    initialize_firebase()

    @app.get("/api/health")
    def health():
        """Check whether Flask and PostgreSQL are working."""

        try:
            db.session.execute(text("SELECT 1"))

            return jsonify({
                "status": "ok",
                "application": "Cashly Campus",
                "database": "connected",
            }), 200

        except Exception:
            app.logger.exception("Database health check failed")

            return jsonify({
                "status": "error",
                "database": "unavailable",
            }), 503

    def firebase_required(function):
        """Require a valid Firebase ID token."""

        @wraps(function)
        def decorated(*args, **kwargs):
            header = request.headers.get(
                "Authorization", ""
            )

            if not header.startswith("Bearer "):
                return jsonify({
                    "error": "Missing Firebase ID token"
                }), 401

            token = header[7:].strip()

            if not token:
                return jsonify({
                    "error": "Empty Firebase ID token"
                }), 401

            try:
                decoded = auth.verify_id_token(
                    token,
                    check_revoked=True,
                )

            except Exception:
                app.logger.warning(
                    "Firebase token verification failed"
                )

                return jsonify({
                    "error": "Invalid or expired Firebase token"
                }), 401

            return function(decoded, *args, **kwargs)

        return decorated

    @app.post("/api/students/sync")
    @firebase_required
    def sync_student(decoded):
        """
        Create a student and wallet for a Firebase user.

        Repeated calls reuse the existing student.
        """

        uid = decoded["uid"]
        email = decoded.get("email")

        if decoded.get("firebase", {}).get(
            "sign_in_provider"
        ) != "password":
            return jsonify({
                "error": "Email/password authentication required"
            }), 403

        try:
            student = Student.query.filter_by(
                firebase_uid=uid
            ).first()

            if student is None:
                student = Student(
                    firebase_uid=uid,
                    email=email,
                )

                db.session.add(student)
                db.session.flush()

                wallet = Wallet(
                    student_id=student.id,
                    balance_sen=0,
                )

                db.session.add(wallet)

                db.session.commit()

            elif student.wallet is None:
                wallet = Wallet(
                    student_id=student.id,
                    balance_sen=0,
                )

                db.session.add(wallet)
                db.session.commit()

            return jsonify({
                "message": "Student account ready",
                "student": student.to_dict(),
                "wallet": student.wallet.to_dict(),
            }), 200

        except IntegrityError:
            db.session.rollback()

            # Another concurrent request may have created
            # this account first. Fetch the existing record.
            student = Student.query.filter_by(
                firebase_uid=uid
            ).first()

            if student is not None and student.wallet is not None:
                return jsonify({
                    "message": "Student account ready",
                    "student": student.to_dict(),
                    "wallet": student.wallet.to_dict(),
                }), 200

            return jsonify({
                "error": "Account creation conflict. Retry."
            }), 409

        except Exception:
            db.session.rollback()
            app.logger.exception(
                "Student synchronization failed"
            )

            return jsonify({
                "error": "Unable to synchronize student"
            }), 500

    @app.get("/api/students/me")
    @firebase_required
    def get_student(decoded):
        """Return only the authenticated student's profile."""

        student = Student.query.filter_by(
            firebase_uid=decoded["uid"]
        ).first()

        if student is None:
            return jsonify({
                "error": "Student profile not found. Sync first."
            }), 404

        return jsonify({
            "student": student.to_dict(),
            "wallet": (
                student.wallet.to_dict()
                if student.wallet else None
            ),
        }), 200

    @app.get("/api/wallet")
    @firebase_required
    def get_wallet(decoded):
        student = Student.query.filter_by(
            firebase_uid=decoded["uid"]
        ).first()

        if student is None or student.wallet is None:
            return jsonify({
                "error": "Student wallet not found. Sync first."
            }), 404

        return jsonify({
            "balance_sen": student.wallet.balance_sen
        }), 200


    @app.post("/api/wallet/topup")
    @firebase_required
    def topup_wallet(decoded):
        data = request.get_json(silent=True) or {}

        amount_sen = data.get("amount_sen")
        key = data.get("idempotency_key")

        if type(amount_sen) is not int:
            return jsonify({
                "error": "amount_sen must be an integer."
            }), 400

        if amount_sen < 100 or amount_sen > 100000:
            return jsonify({
                "error": "Top-up must be between RM1 and RM1000."
            }), 400

        if not isinstance(key, str) or not (
            8 <= len(key) <= 100
        ):
            return jsonify({
                "error": "Invalid idempotency key."
            }), 400

        student = Student.query.filter_by(
            firebase_uid=decoded["uid"]
        ).first()

        if student is None or student.wallet is None:
            return jsonify({
                "error": "Student wallet not found."
            }), 404

        wallet_id = student.wallet.id

        try:
            # Lock the wallet row during the transaction.
            wallet = db.session.execute(
                select(Wallet)
                .where(Wallet.id == wallet_id)
                .with_for_update()
            ).scalar_one()

            existing = WalletTransaction.query.filter_by(
                idempotency_key=key
            ).first()

            if existing is not None:
                if (
                    existing.wallet_id != wallet.id
                    or existing.amount_sen != amount_sen
                    or existing.transaction_type != "TOPUP"
                ):
                    db.session.rollback()
                    return jsonify({
                        "error": "Idempotency key already used."
                    }), 409

                db.session.rollback()
                return jsonify({
                    "message": "Top-up already processed.",
                    "balance_sen": existing.balance_after_sen,
                    "transaction": existing.to_dict(),
                    "duplicate": True,
                }), 200

            wallet.balance_sen += amount_sen

            transaction = WalletTransaction(
                wallet_id=wallet.id,
                transaction_type="TOPUP",
                amount_sen=amount_sen,
                balance_after_sen=wallet.balance_sen,
                idempotency_key=key,
            )

            db.session.add(transaction)
            db.session.commit()

            return jsonify({
                "message": "Simulated top-up successful.",
                "balance_sen": wallet.balance_sen,
                "transaction": transaction.to_dict(),
                "duplicate": False,
            }), 201

        except IntegrityError:
            db.session.rollback()
            return jsonify({
                "error": "Duplicate transaction. Refresh wallet."
            }), 409

        except Exception:
            db.session.rollback()
            app.logger.exception("Wallet top-up failed")
            return jsonify({
                "error": "Unable to process top-up."
            }), 500


    @app.post("/api/wallet/transfer")
    @firebase_required
    def transfer_wallet(decoded):
        """Transfer simulated money between two student wallets."""

        data = request.get_json(silent=True) or {}

        recipient_email = data.get("recipient_email")
        amount_sen = data.get("amount_sen")
        key = data.get("idempotency_key")

        if not isinstance(recipient_email, str):
            return jsonify({
                "error": "Recipient email is required."
            }), 400

        recipient_email = recipient_email.strip().lower()

        if not recipient_email or len(recipient_email) > 255:
            return jsonify({
                "error": "Invalid recipient email."
            }), 400

        if type(amount_sen) is not int:
            return jsonify({
                "error": "Amount must be an integer in sen."
            }), 400

        if amount_sen < 100 or amount_sen > 100000:
            return jsonify({
                "error": "Transfer must be between RM1 and RM1000."
            }), 400

        # Reserve room for the sender/receiver key suffixes.
        if not isinstance(key, str) or not (8 <= len(key) <= 90):
            return jsonify({
                "error": "Invalid transaction key."
            }), 400

        sender = Student.query.filter_by(
            firebase_uid=decoded["uid"]
        ).first()

        if sender is None or sender.wallet is None:
            return jsonify({
                "error": "Sender wallet not found."
            }), 404

        recipients = (
            Student.query
            .filter(db.func.lower(Student.email) == recipient_email)
            .limit(2)
            .all()
        )

        if len(recipients) != 1:
            return jsonify({
                "error": "Recipient not found or email is ambiguous."
            }), 404

        recipient = recipients[0]

        if recipient.id == sender.id:
            return jsonify({
                "error": "You cannot transfer to yourself."
            }), 400

        if recipient.wallet is None:
            return jsonify({
                "error": "Recipient wallet not found."
            }), 404

        sender_wallet_id = sender.wallet.id
        receiver_wallet_id = recipient.wallet.id

        sender_key = f"{key}:S"
        receiver_key = f"{key}:R"

        try:
            # Lock both wallet rows in a consistent order.
            # This reduces the risk of deadlocks.
            wallet_ids = sorted([
                sender_wallet_id,
                receiver_wallet_id,
            ])

            locked_wallets = {}

            for wallet_id in wallet_ids:
                wallet = db.session.execute(
                    select(Wallet)
                    .where(Wallet.id == wallet_id)
                    .with_for_update()
                ).scalar_one()

                locked_wallets[wallet_id] = wallet

            sender_wallet = locked_wallets[sender_wallet_id]
            receiver_wallet = locked_wallets[receiver_wallet_id]

            # Check for a previously completed transfer.
            existing = WalletTransaction.query.filter_by(
                idempotency_key=sender_key
            ).first()

            if existing is not None:
                receiver_existing = WalletTransaction.query.filter_by(
                    idempotency_key=receiver_key
                ).first()

                if (
                    existing.wallet_id != sender_wallet.id
                    or existing.transaction_type != "TRANSFER_OUT"
                    or existing.amount_sen != amount_sen
                    or receiver_existing is None
                    or receiver_existing.wallet_id != receiver_wallet.id
                    or receiver_existing.transaction_type != "TRANSFER_IN"
                    or receiver_existing.amount_sen != amount_sen
                ):
                    db.session.rollback()
                    return jsonify({
                        "error": "Transaction key already used."
                    }), 409

                current_balance = sender_wallet.balance_sen
                db.session.rollback()

                return jsonify({
                    "message": "Transfer already processed.",
                    "balance_sen": current_balance,
                    "duplicate": True,
                }), 200

            # Check that the receiver-side key is also unused.
            receiver_existing = WalletTransaction.query.filter_by(
                idempotency_key=receiver_key
            ).first()

            if receiver_existing is not None:
                db.session.rollback()
                return jsonify({
                    "error": "Transaction key already used."
                }), 409

            if sender_wallet.balance_sen < amount_sen:
                db.session.rollback()
                return jsonify({
                    "error": "Insufficient wallet balance."
                }), 400

            # Update both balances.
            sender_wallet.balance_sen -= amount_sen
            receiver_wallet.balance_sen += amount_sen

            # Create the sender's transaction.
            sender_transaction = WalletTransaction(
                wallet_id=sender_wallet.id,
                transaction_type="TRANSFER_OUT",
                amount_sen=amount_sen,
                balance_after_sen=sender_wallet.balance_sen,
                idempotency_key=sender_key,
            )

            # Create the receiver's transaction.
            receiver_transaction = WalletTransaction(
                wallet_id=receiver_wallet.id,
                transaction_type="TRANSFER_IN",
                amount_sen=amount_sen,
                balance_after_sen=receiver_wallet.balance_sen,
                idempotency_key=receiver_key,
            )

            db.session.add(sender_transaction)
            db.session.add(receiver_transaction)

            # Both wallet updates and history records
            # are saved together or rolled back together.
            db.session.commit()

            return jsonify({
                "message": "Simulated transfer successful.",
                "amount_sen": amount_sen,
                "recipient_email": recipient_email,
                "balance_sen": sender_wallet.balance_sen,
                "duplicate": False,
            }), 201

        except IntegrityError:
            db.session.rollback()
            return jsonify({
                "error": "Transaction conflict. Refresh wallet."
            }), 409

        except Exception:
            db.session.rollback()
            app.logger.exception("Wallet transfer failed")

            return jsonify({
                "error": "Unable to process transfer."
            }), 500

    @app.get("/api/wallet/transactions")
    @firebase_required
    def wallet_transactions(decoded):
        student = Student.query.filter_by(
            firebase_uid=decoded["uid"]
        ).first()

        if student is None or student.wallet is None:
            return jsonify({
                "error": "Student wallet not found."
            }), 404

        transactions = (
            WalletTransaction.query
            .filter_by(wallet_id=student.wallet.id)
            .order_by(
                WalletTransaction.created_at.desc(),
                WalletTransaction.id.desc(),
            )
            .limit(50)
            .all()
        )

        return jsonify({
            "transactions": [
                item.to_dict() for item in transactions
            ]
        }), 200


    @app.get("/api/savings")
    @firebase_required
    def get_savings(decoded):
        student = Student.query.filter_by(
            firebase_uid=decoded["uid"]
        ).first()

        if student is None:
            return jsonify({
                "error": "Student not found"
            }), 404

        savings = SavingsAccount.query.filter_by(
            student_id=student.id
        ).first()

        if savings is None:
            savings = SavingsAccount(
                student_id=student.id,
                balance_sen=0,
            )

            db.session.add(savings)
            db.session.commit()

        return jsonify(savings.to_dict()), 200


    # ==========================================
    # CASHLY CAMPUS - SAVINGS DEPOSIT API
    # ==========================================

    @app.post("/api/savings/deposit")
    @firebase_required
    def deposit_savings(decoded):
        data = request.get_json(silent=True) or {}

        amount_sen = data.get("amount_sen")
        idempotency_key = data.get("idempotency_key")

        # Validate deposit amount
        if (
            type(amount_sen) is not int
            or amount_sen < 100
            or amount_sen > 100000
        ):
            return jsonify({
                "error": "Deposit must be between RM1 and RM1000"
            }), 400

        # Validate idempotency key
        if (
            not isinstance(idempotency_key, str)
            or not 8 <= len(idempotency_key) <= 98
        ):
            return jsonify({
                "error": "Invalid idempotency key"
            }), 400

        try:
            student = Student.query.filter_by(
                firebase_uid=decoded["uid"]
            ).first()

            if student is None:
                return jsonify({
                    "error": "Student not found"
                }), 404

            # Lock wallet first
            wallet = Wallet.query.filter_by(
                student_id=student.id
            ).with_for_update().first()

            if wallet is None:
                return jsonify({
                    "error": "Wallet not found"
                }), 404

            # Lock savings account second
            savings = SavingsAccount.query.filter_by(
                student_id=student.id
            ).with_for_update().first()

            if savings is None:
                return jsonify({
                    "error": "Savings account not found. "
                             "Open Savings first."
                }), 404

            # Prevent the same request being processed twice
            
            # Check whether this request was already processed
            existing = SavingsTransaction.query.filter_by(
                idempotency_key=idempotency_key
            ).first()

            if existing is not None:
                # Reject keys belonging to another request
                if (
                    existing.savings_account_id != savings.id
                    or existing.transaction_type != "DEPOSIT"
                    or existing.amount_sen != amount_sen
                ):
                    return jsonify({
                        "error": "Idempotency key already used"
                    }), 409

                # Safe retry: do not move money again
                return jsonify({
                    "message": "Deposit already processed",
                    "wallet_balance_sen": wallet.balance_sen,
                    "savings_balance_sen": savings.balance_sen,
                    "already_processed": True,
                    "is_simulated": True,
                }), 200

            # Check available wallet balance
            if wallet.balance_sen < amount_sen:
                return jsonify({
                    "error": "Insufficient wallet balance"
                }), 400

            # Move simulated funds
            wallet.balance_sen -= amount_sen
            savings.balance_sen += amount_sen

            # Record outgoing wallet transaction
            wallet_transaction = WalletTransaction(
                wallet_id=wallet.id,
                transaction_type="SAVINGS_DEPOSIT",
                amount_sen=amount_sen,
                balance_after_sen=wallet.balance_sen,
                idempotency_key=idempotency_key + ":W",
            )

            # Record incoming savings transaction
            savings_transaction = SavingsTransaction(
                savings_account_id=savings.id,
                transaction_type="DEPOSIT",
                amount_sen=amount_sen,
                balance_after_sen=savings.balance_sen,
                idempotency_key=idempotency_key,
            )

            db.session.add(wallet_transaction)
            db.session.add(savings_transaction)

            # Both updates are committed together
            db.session.commit()

            return jsonify({
                "message": "Savings deposit successful",
                "wallet_balance_sen": wallet.balance_sen,
                "savings_balance_sen": savings.balance_sen,
                "is_simulated": True,
            }), 201

        except Exception:
            db.session.rollback()
            app.logger.exception("Savings deposit failed")

            return jsonify({
                "error": "Unable to complete savings deposit"
            }), 500

        finally:
            db.session.remove()


    # ==========================================
    # CASHLY CAMPUS - SAVINGS WITHDRAWAL API
    # ==========================================

    @app.post("/api/savings/withdraw")
    @firebase_required
    def withdraw_savings(decoded):
        data = request.get_json(silent=True) or {}

        amount_sen = data.get("amount_sen")
        idempotency_key = data.get("idempotency_key")

        # Validate withdrawal amount
        if (
            type(amount_sen) is not int
            or amount_sen < 100
            or amount_sen > 100000
        ):
            return jsonify({
                "error": "Withdrawal must be between RM1 and RM1000"
            }), 400

        # Validate idempotency key
        if (
            not isinstance(idempotency_key, str)
            or not 8 <= len(idempotency_key) <= 98
        ):
            return jsonify({
                "error": "Invalid idempotency key"
            }), 400

        try:
            student = Student.query.filter_by(
                firebase_uid=decoded["uid"]
            ).first()

            if student is None:
                return jsonify({
                    "error": "Student not found"
                }), 404

            # Lock wallet first, then savings
            wallet = Wallet.query.filter_by(
                student_id=student.id
            ).with_for_update().first()

            if wallet is None:
                return jsonify({
                    "error": "Wallet not found"
                }), 404

            savings = SavingsAccount.query.filter_by(
                student_id=student.id
            ).with_for_update().first()

            if savings is None:
                return jsonify({
                    "error": "Savings account not found"
                }), 404

            # Reject a repeated transaction
            
            # Check whether this request was already processed
            existing = SavingsTransaction.query.filter_by(
                idempotency_key=idempotency_key
            ).first()

            if existing is not None:
                # Reject keys belonging to another request
                if (
                    existing.savings_account_id != savings.id
                    or existing.transaction_type != "WITHDRAW"
                    or existing.amount_sen != amount_sen
                ):
                    return jsonify({
                        "error": "Idempotency key already used"
                    }), 409

                # Safe retry: do not move money again
                return jsonify({
                    "message": "Withdrawal already processed",
                    "wallet_balance_sen": wallet.balance_sen,
                    "savings_balance_sen": savings.balance_sen,
                    "already_processed": True,
                    "is_simulated": True,
                }), 200

            # Check available savings balance
            if savings.balance_sen < amount_sen:
                return jsonify({
                    "error": "Insufficient savings balance"
                }), 400

            # Move simulated money from savings to wallet
            savings.balance_sen -= amount_sen
            wallet.balance_sen += amount_sen

            wallet_transaction = WalletTransaction(
                wallet_id=wallet.id,
                transaction_type="SAVINGS_WITHDRAW",
                amount_sen=amount_sen,
                balance_after_sen=wallet.balance_sen,
                idempotency_key=idempotency_key + ":W",
            )

            savings_transaction = SavingsTransaction(
                savings_account_id=savings.id,
                transaction_type="WITHDRAW",
                amount_sen=amount_sen,
                balance_after_sen=savings.balance_sen,
                idempotency_key=idempotency_key,
            )

            db.session.add(wallet_transaction)
            db.session.add(savings_transaction)

            # Save both balance changes together
            db.session.commit()

            return jsonify({
                "message": "Savings withdrawal successful",
                "wallet_balance_sen": wallet.balance_sen,
                "savings_balance_sen": savings.balance_sen,
                "is_simulated": True,
            }), 201

        except Exception:
            db.session.rollback()
            app.logger.exception("Savings withdrawal failed")

            return jsonify({
                "error": "Unable to complete savings withdrawal"
            }), 500

        finally:
            db.session.remove()

    # ==========================================
    # CASHLY CAMPUS - SAVINGS HISTORY API
    # ==========================================

    @app.get("/api/savings/transactions")
    @firebase_required
    def savings_transactions(decoded):

        # Identify the logged-in student
        student = Student.query.filter_by(
            firebase_uid=decoded["uid"]
        ).first()

        if student is None:
            return jsonify({
                "error": "Student not found"
            }), 404

        # Find the student's savings account
        savings = SavingsAccount.query.filter_by(
            student_id=student.id
        ).first()

        if savings is None:
            return jsonify({
                "transactions": [],
                "is_simulated": True
            }), 200

        # Retrieve the 50 latest transactions
        transactions = (
            SavingsTransaction.query
            .filter_by(savings_account_id=savings.id)
            .order_by(SavingsTransaction.id.desc())
            .limit(50)
            .all()
        )

        return jsonify({
            "transactions": [
                transaction.to_dict()
                for transaction in transactions
            ],
            "is_simulated": True
        }), 200


    # ==========================================
    # CASHLY CAMPUS - RECORD EXPENSE API
    # ==========================================

    @app.post("/api/expenses")
    @firebase_required
    def create_expense(decoded):

        data = request.get_json(silent=True)

        if not isinstance(data, dict):
            return jsonify({
                "error": "A JSON object is required."
            }), 400

        amount_sen = data.get("amount_sen")
        category = data.get("category")
        description = data.get("description", "")
        expense_date_text = data.get("expense_date")

        # Validate amount
        if (
            type(amount_sen) is not int
            or amount_sen < 1
            or amount_sen > 10000000
        ):
            return jsonify({
                "error": "Amount must be between RM0.01 and RM100,000."
            }), 400

        # Validate category
        if (
            not isinstance(category, str)
            or not category.strip()
            or len(category.strip()) > 50
        ):
            return jsonify({
                "error": "Invalid expense category."
            }), 400

        # Validate description
        if (
            not isinstance(description, str)
            or len(description.strip()) > 255
        ):
            return jsonify({
                "error": "Invalid expense description."
            }), 400

        # Validate expense date
        if not isinstance(expense_date_text, str):
            return jsonify({
                "error": "Expense date is required (YYYY-MM-DD)."
            }), 400

        try:
            expense_date = date.fromisoformat(
                expense_date_text
            )
        except ValueError:
            return jsonify({
                "error": "Invalid expense date."
            }), 400

        # Find authenticated student
        student = Student.query.filter_by(
            firebase_uid=decoded["uid"]
        ).first()

        if student is None:
            return jsonify({
                "error": "Student not found. Sync first."
            }), 404

        try:
            expense = Expense(
                student_id=student.id,
                category=category.strip(),
                description=description.strip(),
                amount_sen=amount_sen,
                expense_date=expense_date,
            )

            db.session.add(expense)
            db.session.commit()

            return jsonify({
                "message": "Expense recorded successfully.",
                "expense": expense.to_dict()
            }), 201

        except Exception:
            db.session.rollback()
            app.logger.exception(
                "Failed to record expense"
            )

            return jsonify({
                "error": "Unable to record expense."
            }), 500


    # ==========================================
    # CASHLY CAMPUS - GET EXPENSES API
    # ==========================================

    @app.get("/api/expenses")
    @firebase_required
    def get_expenses(decoded):

        student = Student.query.filter_by(
            firebase_uid=decoded["uid"]
        ).first()

        if student is None:
            return jsonify({
                "error": "Student not found. Sync first."
            }), 404

        query = Expense.query.filter_by(
            student_id=student.id
        )

        # Optional month and year filters
        year_text = request.args.get("year")
        month_text = request.args.get("month")

        if (year_text is None) != (month_text is None):
            return jsonify({
                "error": "Provide both year and month."
            }), 400

        if year_text is not None:
            try:
                year = int(year_text)
                month = int(month_text)

                if (
                    not 2000 <= year <= 2100
                    or not 1 <= month <= 12
                ):
                    raise ValueError()

            except (ValueError, TypeError):
                return jsonify({
                    "error": "Invalid year or month."
                }), 400

            query = query.filter(
                db.extract(
                    "year", Expense.expense_date
                ) == year,
                db.extract(
                    "month", Expense.expense_date
                ) == month,
            )

        expenses = (
            query
            .order_by(
                Expense.expense_date.desc(),
                Expense.id.desc()
            )
            .limit(100)
            .all()
        )

        total_sen = sum(
            expense.amount_sen
            for expense in expenses
        )

        return jsonify({
            "expenses": [
                expense.to_dict()
                for expense in expenses
            ],
            "total_sen": total_sen,
            "count": len(expenses),
            "limit": 100,
            "is_simulated": True
        }), 200

    return app

app = create_app()


if __name__ == "__main__":
    app.run(
        host="127.0.0.1",
        port=5000,
        debug=False,
    )
