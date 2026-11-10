# ER Diagram — My Wallet AI

```mermaid
erDiagram
  USERS ||--o{ AUTH_TOKENS : owns
  USERS ||--o{ CATEGORIES : owns
  USERS ||--o{ TRANSACTIONS : owns
  USERS ||--o{ BUDGETS : sets
  USERS ||--o{ RECEIPTS : uploads
  USERS ||--o{ SUBSCRIPTIONS : tracks
  USERS ||--o{ SUBSCRIPTION_PAYMENTS : pays
  USERS ||--o{ INSTALLMENT_PLANS : tracks
  INSTALLMENT_PLANS ||--|{ INSTALLMENT_PAYMENTS : schedules
  CATEGORIES |o--o{ INSTALLMENT_PLANS : classifies
  TRANSACTIONS |o--o| INSTALLMENT_PLANS : records_down_payment
  TRANSACTIONS |o--o| INSTALLMENT_PAYMENTS : records_installment
  CATEGORIES |o--o{ TRANSACTIONS : classifies
  CATEGORIES |o--o{ BUDGETS : scoped_to
  TRANSACTIONS |o--o| RECEIPTS : evidenced_by
  SUBSCRIPTIONS ||--o{ SUBSCRIPTION_PAYMENTS : generates
  TRANSACTIONS ||--o| SUBSCRIPTION_PAYMENTS : records_payment

  USERS {
    bigint id PK
    varchar name
    varchar email UK
    varchar password_hash
  }
  INSTALLMENT_PLANS {
    bigint id PK
    bigint user_id FK
    bigint category_id FK
    varchar product_name
    decimal price
    decimal down_payment
    bigint down_transaction_id FK
    smallint installment_count
    date first_due_date
    decimal total_payable
    varchar note
  }
  INSTALLMENT_PAYMENTS {
    bigint id PK
    bigint plan_id FK
    smallint installment_number
    date due_date
    decimal amount
    bigint transaction_id FK
    date paid_date
    blob proof_data
    varchar proof_mime
  }
  AUTH_TOKENS {
    bigint id PK
    bigint user_id FK
    char token_hash UK
    datetime expires_at
  }
  CATEGORIES {
    bigint id PK
    bigint user_id FK
    enum type
    varchar name
  }
  TRANSACTIONS {
    bigint id PK
    bigint user_id FK
    bigint category_id FK
    enum type
    decimal amount
    varchar title
    date transaction_date
    enum source
  }
  RECEIPTS {
    bigint id PK
    bigint user_id FK
    bigint transaction_id FK
    varchar file_name
    char sha256
    longtext extracted_json
  }
  BUDGETS {
    bigint id PK
    bigint user_id FK
    bigint category_id FK
    char month_key
    varchar budget_key
    decimal amount
  }
  SUBSCRIPTIONS {
    bigint id PK
    bigint user_id FK
    varchar service_name
    decimal amount
    date start_date
    tinyint billing_day
    enum cycle
  }
  SUBSCRIPTION_PAYMENTS {
    bigint id PK
    bigint user_id FK
    bigint subscription_id FK
    bigint transaction_id FK
    date due_date
  }
```

**หลักการออกแบบ**: รายรับและรายจ่ายอยู่ใน `transactions` ตารางเดียว (`type`) เพื่อรวมยอดสะดวก, `budgets.budget_key` ทำให้มีทั้งงบรวม (`total`) และตามหมวด (`cat_XX`) โดยไม่ซ้ำ, `subscription_payments` ใช้ unique ต่อ `(subscription_id, due_date)` ร่วมกับ row lock ของบริการและการตรวจรอบเดือน/ปีใน API เพื่อกันจ่ายซ้ำแม้เปลี่ยนวันตัดรอบ, `receipts` แยกรูปและข้อมูล AI ออกจากรายการที่ยืนยันแล้ว
