-- Run once against the existing finance_tracker database.
ALTER TABLE transactions MODIFY source ENUM('manual','ai','subscription','installment') NOT NULL DEFAULT 'manual';

CREATE TABLE IF NOT EXISTS installment_plans (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 user_id BIGINT UNSIGNED NOT NULL,
 category_id BIGINT UNSIGNED NULL,
 product_name VARCHAR(100) NOT NULL,
 price DECIMAL(12,2) NOT NULL,
 down_payment DECIMAL(12,2) NOT NULL DEFAULT 0,
 down_transaction_id BIGINT UNSIGNED NULL UNIQUE,
 installment_count SMALLINT UNSIGNED NOT NULL,
 first_due_date DATE NOT NULL,
 total_payable DECIMAL(12,2) NOT NULL,
 note VARCHAR(1000) NOT NULL DEFAULT '',
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
 FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL,
 FOREIGN KEY(down_transaction_id) REFERENCES transactions(id) ON DELETE SET NULL,
 INDEX idx_plan_user(user_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS installment_payments (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 plan_id BIGINT UNSIGNED NOT NULL,
 installment_number SMALLINT UNSIGNED NOT NULL,
 due_date DATE NOT NULL,
 amount DECIMAL(12,2) NOT NULL,
 transaction_id BIGINT UNSIGNED NULL UNIQUE,
 paid_date DATE NULL,
 proof_data MEDIUMBLOB NULL,
 proof_mime VARCHAR(32) NULL,
 FOREIGN KEY(plan_id) REFERENCES installment_plans(id) ON DELETE CASCADE,
 FOREIGN KEY(transaction_id) REFERENCES transactions(id) ON DELETE SET NULL,
 UNIQUE KEY uq_installment(plan_id,installment_number),
 INDEX idx_installment_due(due_date)
) ENGINE=InnoDB;
