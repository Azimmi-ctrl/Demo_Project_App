# Cashly Campus — Product Requirements Document (PRD)

**Project title:** Development of Cashly Campus: A Simulated Student E-Wallet with Expense Tracking and Machine Learning-Based Spending Prediction  
**Document version:** 2.0 (Revised Project Scope)  
**Date:** 2 November 2026  
**Project type:** Bachelor of Computer Science (Software Engineering) — Final Year Project  
**Target institution:** City University Malaysia  
**Platform:** Android mobile application (Flutter)  
**Development approach:** Incremental development with iterative testing  
**Project status:** Prototype under development

> **Important:** Cashly Campus is an educational prototype. All balances, transfers, purchases, savings interest, coins and vouchers use simulated values. The application does **not** hold real money, connect to banks, or provide regulated financial services.

---

## 1. Product Overview

Cashly Campus is a student-focused mobile e-wallet application designed initially for City University Malaysia students. It combines simulated wallet transactions with savings tools, expense tracking, campus vouchers, loyalty coins and machine learning-based spending prediction.

Students will be able to sign in, view their wallet balance, add demo funds, transfer simulated money to other registered students, make simulated QR payments, and manage their spending in one application. A savings feature will allow students to move demo funds into a separate balance and view illustrative interest. Students can also obtain vouchers and earn Campus Coins from eligible simulated campus purchases.

The application will provide manual expense recording, budget monitoring, financial summaries and future monthly spending estimates. The primary purpose is to demonstrate software engineering practices, secure app–backend integration, database transactions and the use of machine learning in personal finance management.

## 2. Problem Statement

University students commonly manage spending across different activities such as meals, transport, shopping and study materials. It can be difficult to understand daily expenses, control monthly budgets and estimate future spending when financial information is not organized in one place.

Existing payment applications may support payments but do not necessarily offer a campus-specific combination of budgeting, learning-oriented savings tools, student rewards and spending predictions. For a final year project, using real financial transactions would also introduce significant security, legal and operational requirements.

Cashly Campus addresses these problems through a controlled, simulated financial environment where students can practise managing money and review their spending behaviour without handling real funds.

## 3. Project Aim and Objectives

**Aim:** To develop a functional Android student e-wallet prototype that supports simulated payments, financial management and machine learning-based spending prediction.

**Objectives:**

1. To design and develop a student e-wallet Android application using Flutter.
2. To implement user registration and login using Firebase Authentication.
3. To develop a Flask API and PostgreSQL database for managing student profiles, wallet balances and financial records.
4. To implement simulated wallet functions, including top-up, student-to-student transfer and QR-based payment.
5. To provide simulated savings management with illustrative annual interest calculations.
6. To enable manual expense recording, expense categories, monthly budgets and spending reports.
7. To provide campus-related vouchers and a loyalty rewards system using Campus Coins.
8. To develop and evaluate a machine learning model for predicting a student's next-month spending using available historical expense data.
9. To test system functionality, data consistency, usability and basic security controls.

## 4. Target Users and Stakeholders

| Stakeholder | Role / needs |
|---|---|
| City University students | Primary users; manage simulated wallet, savings, expenses and rewards |
| Project developer | Designs, develops, integrates and tests the application |
| FYP supervisor | Reviews project scope, implementation, results and documentation |
| Test participants | Evaluate usability and key application functions |
| University (conceptual stakeholder) | Potential future source of campus merchandise, cafeteria and voucher requirements; no official integration is assumed |

The first prototype focuses on student users. A production bank, actual campus merchant or university information system is **not** part of the current implementation.

## 5. Scope of the Project

### 5.1 In Scope

- Android mobile application developed with Flutter and Dart.
- Email/password login and registration using Firebase Authentication.
- Student profile synchronization between Firebase and PostgreSQL.
- Simulated wallet balances stored in PostgreSQL, using integer units of **sen**.
- Simulated top-ups and transaction history.
- Student-to-student simulated transfers using a registered student identifier.
- Demonstration QR payment flow with server-side validation.
- Separate simulated savings balance, deposits, withdrawals and illustrative interest.
- Expense entry, categories, budget setting, warning messages and spending summaries.
- Sample campus merchandise, cafeteria purchases, vouchers and Campus Coins.
- Next-month spending predictions based on historical expense records when sufficient data exists.
- Functional, API, database, usability and basic security testing.

### 5.2 Out of Scope

- Real money, real merchant settlement or withdrawal to a bank.
- Integration with DuitNow, payment gateways, bank accounts or banking APIs.
- Real interest payments, financial products or investment services.
- Verification against official university enrollment records.
- Official City University payment, cafeteria, merchandise or voucher systems.
- iOS release, public App Store/Play Store launch or large-scale production hosting.
- Credit scoring, financial advice or guaranteed prediction accuracy.

## 6. User Roles and Access Control

**Student (primary role):** Can register, log in, view their own balances, create simulated transactions, manage savings, record expenses, claim eligible rewards and view personal reports and predictions.

**System/backend:** Validates Firebase ID tokens, identifies the authenticated user, applies business rules and writes authorized records to PostgreSQL.

**Administrator:** An admin interface is not required for the minimum viable product (MVP). Sample products, vouchers and reward rules may initially be configured by the developer.

A user must never be allowed to choose another user's database ID to read or modify another wallet. The backend derives the acting user's identity from the verified Firebase ID token.

## 7. Core Functional Requirements

**Priority:** P0 = essential MVP; P1 = important extended feature; P2 = optional improvement.

| ID | Module | Requirement | Priority |
|---|---|---|---|
| FR-01 | Authentication | Students can register and log in using email and password | P0 |
| FR-02 | Authentication | Students can log out; protected backend endpoints require a valid Firebase ID token | P0 |
| FR-03 | Student account | The backend creates or updates the authenticated student's profile and initial wallet record | P0 |
| FR-04 | Wallet | Students can view their current simulated wallet balance in RM | P0 |
| FR-05 | Wallet | Students can add valid simulated top-up amounts; the balance and transaction history are saved | P0 |
| FR-06 | Wallet | Students can view their own wallet transaction history | P0 |
| FR-07 | Transfers | Students can transfer simulated funds to another registered student | P1 |
| FR-08 | Transfers | The system rejects invalid amounts, insufficient funds and unsupported recipients | P1 |
| FR-09 | QR payment | Students can scan or enter a supported demo QR payment code and confirm a simulated payment | P1 |
| FR-10 | Savings | Students can view a separate simulated savings balance | P1 |
| FR-11 | Savings | Students can deposit from wallet to savings and withdraw back to wallet | P1 |
| FR-12 | Savings | The app displays estimated interest based on a clearly stated illustrative rate; no actual interest is paid | P1 |
| FR-13 | Expense tracker | Students can manually record an expense with amount, category, date and optional description | P0 |
| FR-14 | Expense tracker | Students can view expenses by category and time period | P1 |
| FR-15 | Budget | Students can set a monthly budget and view spending against it | P0 |
| FR-16 | Budget | Students receive warnings when spending approaches or exceeds a configured threshold | P1 |
| FR-17 | Reports | Students can view spending summaries and simple charts | P1 |
| FR-18 | Marketplace | Students can browse sample campus products and make simulated purchases | P1 |
| FR-19 | Vouchers | Students can claim and redeem eligible demo vouchers according to rules | P1 |
| FR-20 | Campus Coins | Eligible simulated purchases earn coins according to defined reward rules | P1 |
| FR-21 | Campus Coins | Students can view coin balances and redeem eligible demo rewards | P1 |
| FR-22 | ML prediction | The system estimates next-month spending when there is sufficient usable history | P1 |
| FR-23 | ML prediction | The app shows a clear “insufficient data” message when a reliable model input cannot be formed | P1 |
| FR-24 | Profile | Students can view basic account information and access logout | P0 |
| FR-25 | Reliability | Financial updates are recorded consistently and cannot create a negative balance | P0 |

## 8. Key User Stories and Acceptance Criteria

### US-01: Student sign-in

**As a** student, **I want** to log in securely **so that** only I can access my account.

- Given valid credentials, the student reaches the main application.
- Invalid credentials produce a helpful error message.
- Protected API requests without a valid Firebase ID token are rejected.

### US-02: Wallet balance and top-up

**As a** student, **I want** to add demo funds **so that** I can try the e-wallet features.

- The Home page shows the balance returned by the backend, not a hardcoded amount.
- A valid top-up creates a wallet transaction and updates the database balance.
- The updated balance remains correct after closing and reopening the app.
- Zero, negative or incorrectly formatted amounts are rejected.

### US-03: Transfer simulated money

**As a** student, **I want** to transfer demo funds to another registered student.

- Both student wallets are updated together in one database transaction.
- Insufficient funds, invalid recipients and self-transfers are rejected.
- A successful transfer appears in both students' transaction histories.

### US-04: Savings

**As a** student, **I want** to move demo money between my wallet and savings balance.

- Deposits cannot exceed the available wallet balance.
- Withdrawals cannot exceed the savings balance.
- The displayed interest is clearly marked as illustrative.

### US-05: Budget and expense report

**As a** student, **I want** to track my spending **so that** I know whether I am following my budget.

- A student can record manual expenses and see them in the correct month and category.
- Spending totals and budget percentage are calculated correctly.
- Warning messages appear at defined thresholds (for example 70%, 90% and 100%).

### US-06: Spending prediction

**As a** student, **I want** to estimate next month's spending **so that** I can plan my budget.

- Predictions use the student's historical records or an explicitly defined experimental dataset.
- The displayed output includes an estimated RM amount and a note that it is not guaranteed.
- If history is insufficient, the system explains why prediction is unavailable.

## 9. Application Pages and Navigation

| Page | Main contents / interactions |
|---|---|
| Login / Register | Email, password, sign-in, registration and error messages |
| Home | Welcome message, backend wallet balance, Top Up, Transfer, Scan & Pay, Savings shortcut, overview and recent activity |
| Finance | Savings balance, deposit/withdraw, illustrative interest, manual expenses, budget, reports and ML prediction |
| Campus | Sample cafeteria products, university merchandise and simulated purchase actions |
| Rewards | Campus Coins balance, earn/redeem rules, voucher claim and voucher redemption |
| Profile | Account information, logout and development-only connection testing tools |
| Wallet History / Details | Saved simulated transactions, amounts, transaction types and timestamps |

**Navigation:** The prototype uses a bottom navigation bar for **Home**, **Finance**, **Campus**, **Rewards** and **Profile**. Development/testing pages may be removed from the student-facing interface once their features are integrated.

## 10. Technology Stack and Architecture

| Layer | Selected technology | Purpose |
|---|---|---|
| Mobile frontend | Flutter (Dart) | Android screens, navigation, forms and charts |
| Authentication | Firebase Authentication (Email/Password) | Registration, login and identity tokens |
| Backend | Python Flask | API routes, input validation and business logic |
| Database | PostgreSQL | Persistent student, wallet, transaction and expense data |
| ML development | Python, pandas, scikit-learn | Data preparation, model training and evaluation |
| Development tools | VS Code, Android emulator, Git/GitHub, pgAdmin | Development, testing and version control |

### 10.1 High-Level Data Flow

```text
Student (Flutter Android App)
          |
          | Firebase Email/Password sign-in
          v
 Firebase Authentication
          |
          | Firebase ID token
          v
 Flutter App ---- HTTPS/API requests ----> Flask Backend
                                          |        |
                                          |        +--> Verify Firebase ID token
                                          |
                                          +--> PostgreSQL database
                                          |
                                          +--> ML prediction component
```

During local emulator development, Android may access Flask on the host machine through `http://10.0.2.2:5000`. For deployment outside the local environment, authenticated APIs should use HTTPS.

### 10.2 Important Design Principle

**PostgreSQL is the source of truth for wallet balances.** The Flutter app must display the balance returned by the backend. Frontend-only variables must not be treated as real stored wallet data.

## 11. Proposed Database Design

The following is the **target logical design**, not a claim that every table is already implemented.

| Table | Main example fields | Purpose |
|---|---|---|
| `students` | `id`, `firebase_uid`, `email`, `created_at` | Link Firebase accounts to local student records |
| `wallets` | `id`, `student_id`, `balance_sen`, `updated_at` | Store each student's simulated wallet balance |
| `wallet_transactions` | `id`, `wallet_id`, `type`, `amount_sen`, `reference`, `created_at` | Store top-up, transfer, payment and reward history |
| `transfers` | `id`, `sender_id`, `recipient_id`, `amount_sen`, `status`, `created_at` | Record student-to-student transfers |
| `savings_accounts` | `id`, `student_id`, `balance_sen`, `updated_at` | Maintain separate savings balances |
| `savings_transactions` | `id`, `student_id`, `type`, `amount_sen`, `created_at` | Store deposits and withdrawals |
| `expenses` | `id`, `student_id`, `category_id`, `amount_sen`, `description`, `expense_date` | Store manual expense entries |
| `expense_categories` | `id`, `name` | Maintain categories such as Food, Transport and Shopping |
| `budgets` | `id`, `student_id`, `month`, `year`, `limit_sen` | Save monthly spending limits |
| `campus_products` | `id`, `name`, `price_sen`, `is_active` | List demo cafeteria and merchandise products |
| `purchases` | `id`, `student_id`, `product_id`, `amount_sen`, `created_at` | Record simulated purchases |
| `vouchers` | `id`, `title`, `discount_sen`, `conditions`, `is_active` | Store voucher definitions |
| `student_vouchers` | `id`, `student_id`, `voucher_id`, `status`, `redeemed_at` | Track claims and redemptions |
| `coin_ledger` | `id`, `student_id`, `delta_coins`, `reason`, `created_at` | Record coin earnings and redemptions |
| `prediction_results` | `id`, `student_id`, `target_month`, `predicted_sen`, `model_version`, `created_at` | Optional prediction history |

**Database rules:** Use integer sen for money; enforce nonnegative wallet and savings balances; use unique constraints on student identity; link records with foreign keys; and use atomic database transactions for transfers and multi-balance operations.

## 12. Backend API Requirements

The following list describes **planned API behaviour**. Actual route names must match the implemented Flask backend and will be finalized during development.

| Method | Example route | Purpose |
|---|---|---|
| GET | `/api/health` | Check backend service status |
| POST | `/api/students/sync` | Create or synchronize the authenticated student |
| GET | `/api/wallet` | Get current student's balance |
| POST | `/api/wallet/top-up` | Add simulated wallet funds |
| GET | `/api/wallet/transactions` | View own wallet transaction history |
| POST | `/api/transfers` | Transfer simulated money to another student |
| POST | `/api/payments/qr` | Process supported simulated QR payment |
| GET | `/api/savings` | View savings balance and rate information |
| POST | `/api/savings/deposit` | Move wallet funds to savings |
| POST | `/api/savings/withdraw` | Move savings funds to wallet |
| GET / POST | `/api/expenses` | View and create expense records |
| GET / PUT | `/api/budgets/current` | View and change current monthly budget |
| GET | `/api/reports/monthly` | Return monthly expense summary |
| GET | `/api/products` | List sample campus products |
| POST | `/api/purchases` | Complete simulated campus purchase |
| GET / POST | `/api/vouchers` | View available vouchers / handle eligible claims as designed |
| GET | `/api/coins` | View coin balance and history |
| POST | `/api/coins/redeem` | Redeem eligible coin reward |
| GET | `/api/predictions/next-month` | Request estimated next-month spending |

**API requirements:** Check the verified user's identity, validate every amount and recipient, return appropriate HTTP status codes, prevent duplicate financial operations where possible, and never trust a wallet balance supplied by the client.

## 13. Machine Learning Requirements and Methodology

### 13.1 Prediction Goal

Predict a student's **next-month total spending** in RM based on available historical expense information. The prediction is for educational budgeting support, not financial advice.

### 13.2 Candidate Features

Depending on data availability:

- Total spending in previous months.
- Spending by category (for example food, transport and shopping).
- Number of expense transactions in each month.
- Month number and recent spending trend.
- Previous month's budget and total spending, if available.

### 13.3 Algorithms

- **Linear Regression:** A simple baseline model for comparing predicted and actual spending.
- **Random Forest Regressor:** A candidate main model that can learn nonlinear relationships in spending patterns.

The final model should be selected based on evaluation results, not assumed to be better in advance.

### 13.4 Data Collection and Preparation

- Primary app records are entered by users manually and may include simulated wallet spending.
- A small experimental or synthetic dataset may be used during research or initial testing, but it must be clearly labelled and separated from real user observations.
- Clean invalid entries, aggregate data by month and form training examples from **past** months only.
- Avoid using future information when constructing input features.
- When user history is too limited, do not invent a personalized prediction.

### 13.5 Evaluation

Evaluate the model using suitable regression measures such as **MAE**, **RMSE** and **R²**, with chronological train/test separation where feasible. Compare predictions against a simple baseline, such as using the previous month's total as the next-month forecast. Report limitations caused by small datasets and irregular spending patterns.

### 13.6 Prediction Display

The app should show the predicted amount, target month, brief explanation and an indication that the value is an estimate. An unavailable prediction must be handled clearly.

## 14. Non-Functional Requirements

| ID | Category | Requirement |
|---|---|---|
| NFR-01 | Usability | Navigation and form labels use clear, student-friendly wording |
| NFR-02 | Performance | Common screens and local API requests should respond promptly under normal test conditions; actual timings will be measured |
| NFR-03 | Reliability | Stored balances remain consistent after app restarts and failed requests |
| NFR-04 | Security | Backend verifies Firebase ID tokens on protected endpoints |
| NFR-05 | Data protection | One student cannot view or change another student's private financial records |
| NFR-06 | Validation | Invalid amounts, empty required fields and unauthorized operations are rejected server-side |
| NFR-07 | Data integrity | Multi-account financial operations use PostgreSQL transactions to prevent partial updates |
| NFR-08 | Maintainability | Separate Flutter UI, API service, Flask business logic and database responsibilities |
| NFR-09 | Compatibility | Support the selected Android emulator and the Android versions identified during testing |
| NFR-10 | Auditability | Keep a transaction record for balance-changing actions and important simulated payments |
| NFR-11 | Privacy | Collect only information necessary for the prototype; do not store passwords in PostgreSQL |
| NFR-12 | Transparency | Every financial screen clearly indicates the money and rewards are simulated |

## 15. Business Rules and Validation

1. **No real-money activity:** Every top-up, payment, transfer, interest value and reward is simulated.
2. **Money representation:** The database stores monetary amounts as integer sen (for example, RM12.50 = 1,250 sen).
3. **Positive amounts:** Top-ups, transfers, payments and deposits require positive valid amounts.
4. **Sufficient funds:** A wallet debit must not exceed its available balance.
5. **Atomic updates:** Transfers, savings movements and eligible purchases must either complete fully or leave balances unchanged.
6. **Account ownership:** Each authenticated user can access only their own wallet and private records, except an authorized recipient credit created through a validated transfer.
7. **QR payment:** Only supported demo QR payloads or test merchant identifiers are accepted.
8. **Savings interest:** An example simple annual rate (initial UI assumption: **3%**) is illustrative and may be changed or configured; it is not automatically paid unless explicitly implemented as a separate simulation rule.
9. **Budget warnings:** The app may notify the user at defined budget usage levels such as 70%, 90% and 100%.
10. **Campus Coins:** Initial demo rule: earn **1 coin for every full RM5** spent on eligible simulated purchases; rules must be applied consistently by the backend when integrated.
11. **Coin redemption:** An initial demo example is **100 coins for RM1 simulated credit**, subject to available coins and backend validation.
12. **Vouchers:** A voucher must respect its claim/redeem conditions and must not be redeemed more than allowed.
13. **ML:** Personalized prediction is not promised when the student has insufficient historical expense data.

## 16. Development Phases and Deliverables

| Phase | Main activities | Expected deliverable |
|---|---|---|
| Phase 1: Planning and setup | Scope, PRD, Flutter/Firebase/Flask/PostgreSQL environment | Approved requirements and working project setup |
| Phase 2: Authentication and wallet foundation | Firebase sign-in, backend verification, student sync, database wallet, top-up, history | Authenticated app with persistent demo wallet |
| Phase 3: Transfers and QR payments | Student transfers, recipient validation, demo QR flow | Simulated transfer/payment module |
| Phase 4: Savings | Separate account, deposit, withdrawal and illustrative interest | Savings management module |
| Phase 5: Campus and rewards | Products, voucher rules, purchases and coin ledger | Campus marketplace and loyalty module |
| Phase 6: Expense and budget tools | Manual entries, categories, monthly budget, warnings and reports | Smart expense tracker module |
| Phase 7: ML integration | Dataset preparation, training, evaluation and prediction endpoint | Evaluated next-month spending prediction |
| Phase 8: UI/UX, testing and documentation | Design refinement, integration testing, usability testing and FYP write-up | Final prototype, test results and project report |

**Current implementation note (2 November 2026):** The Flutter application and emulator are running; Firebase Authentication, Flask and PostgreSQL have been configured; backend connection testing has succeeded; and a database-wallet test screen has been developed. The Home page's live balance display is **not yet verified as working**, and the current Home Top Up, transfer, savings and purchase actions still include frontend-only demonstration logic. Therefore, Phase 2 remains **in progress**. Later modules may have demo UI screens without completed backend integration.

## 17. Testing and Acceptance Plan

### 17.1 Functional Tests

- Register, log in and log out with expected results.
- Reject unauthenticated protected API requests.
- Sync a new user and create a wallet without unwanted duplicates.
- Top up a wallet and confirm the saved balance survives restart.
- Reject invalid, negative and excessive transaction amounts.
- Transfer between two test students and confirm matching sender/recipient records.
- Reject insufficient funds and invalid recipients.
- Deposit/withdraw savings while checking both balances.
- Record an expense and verify correct monthly/category totals.
- Verify budget warnings at defined thresholds.
- Check voucher claim/redeem and coin calculations.
- Display valid prediction outputs and insufficient-data messages.

### 17.2 Integration and Database Tests

- Flutter sends Firebase ID token to Flask where required.
- Flask verifies the token and uses the associated student identity.
- Database transactions roll back when part of a transfer fails.
- Repeated requests do not create accidental duplicate credits if retry protection is implemented.
- Errors return understandable messages instead of silently showing wrong balances.

### 17.3 Usability Tests

Ask student testers to complete selected tasks (login, wallet top-up, view transaction history, set budget, record expense). Collect task completion rates, issues, feedback and simple usability ratings. Document changes made following feedback.

### 17.4 Overall Acceptance Criteria

The core prototype is acceptable when P0 requirements work end-to-end, saved wallet values match the backend, the app avoids real-money claims, key errors are handled, and required tests are documented. P1 modules are evaluated individually against their acceptance criteria and should not be described as complete until integrated and tested.

## 18. Assumptions, Constraints and Risks

| Risk / constraint | Impact | Mitigation |
|---|---|---|
| Limited real user expense history | Predictions may be weak or unavailable | Use clearly identified test data and report limitations |
| Internet/connectivity dependency | Firebase sign-in or API requests may fail | Show errors and retry options; test offline/failed-network states |
| Small FYP development timeline | Not all modules may be fully polished | Prioritize P0, then P1; integrate one module at a time |
| Flutter–Flask–PostgreSQL integration issues | Screen shows outdated or unavailable data | Use one backend source of truth and add API/integration tests |
| Database concurrency | Incorrect balances during simultaneous transactions | Use atomic SQL transactions and safe balance-update rules |
| Sensitive credentials | Unauthorized access if keys are exposed | Use `.env`, keep secrets out of GitHub and restrict service-account files |
| Simulated money may be mistaken for real money | Misleading user experience | Display visible simulated-funds disclaimer |
| University/merchant involvement is not confirmed | Scope could be misunderstood | Label all products, QR codes and vouchers as samples |

## 19. Success Measures

The project will measure success using evidence from:

- Completion of essential functional requirements and identified extended features.
- Correctness of wallet and savings balances after relevant operations.
- Successful handling of invalid and unauthorized API requests.
- Results of test cases and any issues resolved.
- Student usability feedback and task completion.
- Regression model evaluation (MAE, RMSE and R² where meaningful).
- Clear documentation of features completed, limitations and future work.

No fixed accuracy, performance or satisfaction percentage is claimed before testing.

## 20. Future Enhancements

Possible developments beyond the FYP include wider campus support, verified student enrollment, official merchant partnerships, more sophisticated spending insights, notifications, improved QR support and an iOS application. Any connection to real financial services would require separate legal, security, operational and compliance assessment; it is **not** implied by this prototype.

## 21. Glossary

| Term | Meaning |
|---|---|
| E-wallet | An application that displays and manages a balance; in this project it uses only simulated money |
| API | Application Programming Interface; communication between Flutter and Flask |
| Firebase Authentication | Service that manages student sign-in and identity tokens |
| PostgreSQL | Relational database used to save persistent application data |
| QR payment | A demo payment started from a supported QR code or QR-like payload |
| Campus Coins | Simulated loyalty points earned through eligible campus demo purchases |
| ML | Machine Learning; statistical models trained on historical data to estimate future spending |
| MAE / RMSE / R² | Metrics used to evaluate regression prediction performance |
| MVP | Minimum Viable Product; the essential working feature set |

---

**End of PRD — Cashly Campus, version 2.0.**
