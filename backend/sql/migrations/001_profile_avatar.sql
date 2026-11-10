-- Add profile photo storage without changing existing users or passwords.
USE finance_tracker;
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS avatar_data MEDIUMBLOB NULL,
  ADD COLUMN IF NOT EXISTS avatar_mime VARCHAR(32) NULL;
