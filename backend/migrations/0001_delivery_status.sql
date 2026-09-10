-- Additive migration: preserve player scores, subscriptions and existing messages.
ALTER TABLE notifications ADD COLUMN delivery_status TEXT NOT NULL DEFAULT 'pending';
