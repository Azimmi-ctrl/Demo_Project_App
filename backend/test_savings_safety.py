
import os
from concurrent.futures import ThreadPoolExecutor
from unittest.mock import patch
from uuid import uuid4

from sqlalchemy import text
from sqlalchemy.engine import make_url

import app as backend
from models import db, Student, Wallet, SavingsAccount, SavingsTransaction


TEST_DATABASE = "cashly_campus_safety_test"
database_url = os.environ.get("TEST_DATABASE_URL")

if not database_url:
    raise SystemExit(
        "STOP: TEST_DATABASE_URL is not configured."
    )

url = make_url(database_url)

if (
    not url.get_backend_name().startswith("postgresql")
    or url.database != TEST_DATABASE
):
    raise SystemExit(
        "STOP: Tests must use PostgreSQL database "
        f"'{TEST_DATABASE}' only."
    )


# Override the database used by a NEW Flask app.
# Never modify the main app's database configuration.
class SafetyConfig(backend.Config):
    SQLALCHEMY_DATABASE_URI = database_url
    TESTING = True


backend.Config = SafetyConfig
app = backend.create_app()

test_uid = "safety-" + uuid4().hex
headers = {
    "Authorization": "Bearer local-test-token",
    "Content-Type": "application/json",
}


def post(endpoint, amount, key):
    with app.test_client() as client:
        response = client.post(
            endpoint,
            json={
                "amount_sen": amount,
                "idempotency_key": key,
            },
            headers=headers,
        )
        return response.status_code, response.get_json()


def balances():
    with app.app_context():
        student = Student.query.filter_by(
            firebase_uid=test_uid
        ).one()

        wallet = Wallet.query.filter_by(
            student_id=student.id
        ).one()

        savings = SavingsAccount.query.filter_by(
            student_id=student.id
        ).one()

        return wallet.balance_sen, savings.balance_sen


with app.app_context():
    actual_database = db.session.execute(
        text("SELECT current_database()")
    ).scalar_one()

    if actual_database != TEST_DATABASE:
        raise SystemExit(
            "STOP: Connected to the wrong database."
        )

    # Create tables only in our isolated test database.
    db.create_all()

    student = Student(
        firebase_uid=test_uid,
        email=f"{test_uid}@example.test",
    )
    db.session.add(student)
    db.session.flush()

    db.session.add(
        Wallet(
            student_id=student.id,
            balance_sen=10000,
        )
    )
    db.session.add(
        SavingsAccount(
            student_id=student.id,
            balance_sen=2000,
        )
    )
    db.session.commit()

print("Connected to isolated test database.")
print("Starting balances:", balances())

deposit_url = "/api/savings/deposit"
withdraw_url = "/api/savings/withdraw"

deposit_key = str(uuid4())
withdraw_key = str(uuid4())

# Mock Firebase authentication for this isolated local test.
# The real application's Firebase validation is not changed.
with patch.object(
    backend.auth,
    "verify_id_token",
    return_value={"uid": test_uid},
):

    # TEST 1: Normal deposit.
    status, data = post(deposit_url, 1000, deposit_key)
    assert status == 201, (status, data)
    assert balances() == (9000, 3000)
    print("PASS: Normal deposit")

    # TEST 2: Duplicate deposit with same key.
    status, data = post(deposit_url, 1000, deposit_key)
    assert status == 200, (status, data)
    assert data.get("already_processed") is True
    assert balances() == (9000, 3000)
    print("PASS: Duplicate deposit prevented")

    # TEST 3: Same key, different amount.
    status, data = post(deposit_url, 1500, deposit_key)
    assert status == 409, (status, data)
    assert balances() == (9000, 3000)
    print("PASS: Changed amount rejected")

    # TEST 4: Same key, different operation.
    status, data = post(withdraw_url, 1000, deposit_key)
    assert status == 409, (status, data)
    assert balances() == (9000, 3000)
    print("PASS: Changed operation rejected")

    # TEST 5: Normal withdrawal.
    status, data = post(withdraw_url, 500, withdraw_key)
    assert status == 201, (status, data)
    assert balances() == (9500, 2500)
    print("PASS: Normal withdrawal")

    # TEST 6: Duplicate withdrawal.
    status, data = post(withdraw_url, 500, withdraw_key)
    assert status == 200, (status, data)
    assert data.get("already_processed") is True
    assert balances() == (9500, 2500)
    print("PASS: Duplicate withdrawal prevented")

    # TEST 7: Concurrent deposits.
    # Both request RM80, but Wallet has only RM95.
    # Only one request should succeed.
    key_a = str(uuid4())
    key_b = str(uuid4())

    with ThreadPoolExecutor(max_workers=2) as executor:
        future_a = executor.submit(
            post, deposit_url, 8000, key_a
        )
        future_b = executor.submit(
            post, deposit_url, 8000, key_b
        )

        result_a = future_a.result()
        result_b = future_b.result()

    results = [result_a, result_b]
    codes = sorted(item[0] for item in results)

    assert codes == [201, 400], results
    assert balances() == (1500, 10500), balances()
    print("PASS: Concurrent overspending prevented")

    # TEST 8: Money conservation and history count.
    with app.app_context():
        student = Student.query.filter_by(
            firebase_uid=test_uid
        ).one()

        savings = SavingsAccount.query.filter_by(
            student_id=student.id
        ).one()

        count = SavingsTransaction.query.filter_by(
            savings_account_id=savings.id
        ).count()

        assert count == 3, count

    wallet_sen, savings_sen = balances()

    assert wallet_sen + savings_sen == 12000
    print("PASS: Money conservation and history count")

print()
print("ALL 8 SAVINGS SAFETY TESTS PASSED!")
