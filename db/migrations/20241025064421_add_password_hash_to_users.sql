-- migrate:up
ALTER TABLE
  users
ADD
  COLUMN password_hash TEXT;

-- migrate:down
ALTER TABLE
  users DROP COLUMN password_hash;