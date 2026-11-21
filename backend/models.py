
from datetime import datetime, timezone

from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import CheckConstraint


db = SQLAlchemy()


class Student(db.Model):
    __tablename__ = "students"

    id = db.Column(
        db.Integer,
        primary_key=True,
    )

    firebase_uid = db.Column(
        db.String(128),
        unique=True,
        nullable=False,
        index=True,
    )

    email = db.Column(
        db.String(255),
        nullable=True,
    )

    full_name = db.Column(
        db.String(150),
        nullable=True,
    )

    student_id = db.Column(
        db.String(50),
        unique=True,
        nullable=True,
    )

    created_at = db.Column(
        db.DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    wallet = db.relationship(
        "Wallet",
        back_populates="student",
        uselist=False,
    )

    def to_dict(self):
        return {
            "id": self.id,
            "firebase_uid": self.firebase_uid,
            "email": self.email,
            "full_name": self.full_name,
            "student_id": self.student_id,
        }


class Wallet(db.Model):
    __tablename__ = "wallets"

    id = db.Column(
        db.Integer,
        primary_key=True,
    )

    student_id = db.Column(
        db.Integer,
        db.ForeignKey("students.id"),
        unique=True,
        nullable=False,
    )

    balance_sen = db.Column(
        db.BigInteger,
        nullable=False,
        default=0,
    )

    student = db.relationship(
        "Student",
        back_populates="wallet",
    )

    __table_args__ = (
        CheckConstraint(
            "balance_sen >= 0",
            name="wallet_nonnegative_balance",
        ),
    )

    def to_dict(self):
        return {
            "id": self.id,
            "balance_sen": self.balance_sen,
            "currency": "MYR",
            "is_simulated": True,
        }

class WalletTransaction(db.Model):
    __tablename__ = "wallet_transactions"

    id = db.Column(db.Integer, primary_key=True)

    wallet_id = db.Column(
        db.Integer,
        db.ForeignKey("wallets.id"),
        nullable=False,
        index=True,
    )

    transaction_type = db.Column(
        db.String(30),
        nullable=False,
    )

    amount_sen = db.Column(
        db.BigInteger,
        nullable=False,
    )

    balance_after_sen = db.Column(
        db.BigInteger,
        nullable=False,
    )

    idempotency_key = db.Column(
        db.String(100),
        nullable=False,
        unique=True,
    )

    created_at = db.Column(
        db.DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )

    __table_args__ = (
        db.CheckConstraint(
            "amount_sen > 0",
            name="ck_wallet_transaction_positive",
        ),
    )

    def to_dict(self):
        return {
            "id": self.id,
            "transaction_type": self.transaction_type,
            "amount_sen": self.amount_sen,
            "balance_after_sen": self.balance_after_sen,
            "created_at": self.created_at.isoformat(),
        }

# ==========================================
# CASHLY CAMPUS - SAVINGS ACCOUNT
# ==========================================

class SavingsAccount(db.Model):
    __tablename__ = "savings_accounts"

    id = db.Column(db.Integer, primary_key=True)

    student_id = db.Column(
        db.Integer,
        db.ForeignKey("students.id"),
        unique=True,
        nullable=False,
    )

    balance_sen = db.Column(
        db.BigInteger,
        nullable=False,
        default=0,
    )

    created_at = db.Column(
        db.DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    __table_args__ = (
        db.CheckConstraint(
            "balance_sen >= 0",
            name="ck_savings_nonnegative_balance",
        ),
    )

    def to_dict(self):
        return {
            "id": self.id,
            "student_id": self.student_id,
            "balance_sen": self.balance_sen,
            "currency": "MYR",
            "is_simulated": True,
        }


# ==========================================
# CASHLY CAMPUS - SAVINGS TRANSACTIONS
# ==========================================

class SavingsTransaction(db.Model):
    __tablename__ = "savings_transactions"

    id = db.Column(db.Integer, primary_key=True)

    savings_account_id = db.Column(
        db.Integer,
        db.ForeignKey("savings_accounts.id"),
        nullable=False,
        index=True,
    )

    transaction_type = db.Column(
        db.String(20),
        nullable=False,
    )

    amount_sen = db.Column(
        db.BigInteger,
        nullable=False,
    )

    balance_after_sen = db.Column(
        db.BigInteger,
        nullable=False,
    )

    idempotency_key = db.Column(
        db.String(100),
        unique=True,
        nullable=False,
    )

    created_at = db.Column(
        db.DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    __table_args__ = (
        db.CheckConstraint(
            "amount_sen > 0",
            name="ck_savings_transaction_positive",
        ),
    )

    def to_dict(self):
        return {
            "id": self.id,
            "transaction_type": self.transaction_type,
            "amount_sen": self.amount_sen,
            "balance_after_sen": self.balance_after_sen,
            "created_at": self.created_at.isoformat(),
        }

class Expense(db.Model):
    __tablename__ = "expenses"

    id = db.Column(
        db.Integer,
        primary_key=True
    )

    student_id = db.Column(
        db.Integer,
        db.ForeignKey("students.id"),
        nullable=False,
        index=True
    )

    category = db.Column(
        db.String(50),
        nullable=False
    )

    description = db.Column(
        db.String(255),
        nullable=False
    )

    amount_sen = db.Column(
        db.BigInteger,
        nullable=False
    )

    expense_date = db.Column(
        db.Date,
        nullable=False
    )

    created_at = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )

    __table_args__ = (
        db.CheckConstraint(
            "amount_sen > 0",
            name="ck_expense_positive_amount"
        ),
    )

    def to_dict(self):
        return {
            "id": self.id,
            "student_id": self.student_id,
            "category": self.category,
            "description": self.description,
            "amount_sen": self.amount_sen,
            "expense_date": self.expense_date.isoformat(),
            "created_at": self.created_at.isoformat(),
            "currency": "MYR",
            "is_simulated": True
        }


class MonthlyBudget(db.Model):
    __tablename__ = "monthly_budgets"

    id = db.Column(
        db.Integer,
        primary_key=True
    )

    student_id = db.Column(
        db.Integer,
        db.ForeignKey("students.id"),
        nullable=False,
        index=True
    )

    year = db.Column(
        db.Integer,
        nullable=False
    )

    month = db.Column(
        db.Integer,
        nullable=False
    )

    budget_sen = db.Column(
        db.BigInteger,
        nullable=False
    )

    created_at = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )

    __table_args__ = (
        db.UniqueConstraint(
            "student_id",
            "year",
            "month",
            name="uq_student_monthly_budget"
        ),
        db.CheckConstraint(
            "budget_sen >= 0",
            name="ck_monthly_budget_nonnegative"
        ),
        db.CheckConstraint(
            "month BETWEEN 1 AND 12",
            name="ck_monthly_budget_valid_month"
        ),
        db.CheckConstraint(
            "year BETWEEN 2000 AND 2100",
            name="ck_monthly_budget_valid_year"
        ),
    )

    def to_dict(self):
        return {
            "id": self.id,
            "student_id": self.student_id,
            "year": self.year,
            "month": self.month,
            "budget_sen": self.budget_sen,
            "currency": "MYR"
        }
