-- ========= SQL MIGRATION SCRIPT =========
-- This script corrects the schema mismatches.

-- Step 1: Modify the 'transactions' table

-- First, remove the old CHECK constraints on 'type' and 'status'
-- Note: Find the actual constraint names from your Supabase table definition if they are different.
-- You can find them in the Supabase Dashboard: Table Editor -> select 'transactions' -> Properties
ALTER TABLE public.transactions DROP CONSTRAINT IF EXISTS "transactions_type_check";
ALTER TABLE public.transactions DROP CONSTRAINT IF EXISTS "transactions_status_check";

-- Add new CHECK constraints to allow the values used in the PHP/Flutter code
ALTER TABLE public.transactions ADD CONSTRAINT transactions_type_check_new CHECK (type IN ('deposit', 'withdraw', 'credit'));
ALTER TABLE public.transactions ADD CONSTRAINT transactions_status_check_new CHECK (status IN ('pending', 'success', 'failed', 'approved', 'rejected'));


-- Step 2: Update the stored procedures to use UUIDs for user_id
-- We need to change function parameters from INT to UUID.

-- For process_deposit_request
DROP FUNCTION IF EXISTS process_deposit_request(integer, text);
CREATE OR REPLACE FUNCTION process_deposit_request(p_tx_id integer, p_action text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  tx_user_id UUID;   -- Changed from INT to UUID
  tx_amount INTEGER;
BEGIN
  SELECT user_id, amount INTO tx_user_id, tx_amount
  FROM public.transactions WHERE id = p_tx_id AND type = 'deposit' AND status = 'pending';

  IF NOT FOUND THEN RETURN 'Deposit request not found or already processed.'; END IF;

  IF p_action = 'approve' THEN
    UPDATE public.transactions SET status = 'success' WHERE id = p_tx_id;
    UPDATE public.users SET wallet_balance = wallet_balance + tx_amount WHERE id = tx_user_id;
    RETURN 'Deposit approved. User wallet updated.';
  ELSIF p_action = 'reject' THEN
    UPDATE public.transactions SET status = 'failed' WHERE id = p_tx_id;
    RETURN 'Deposit request rejected.';
  ELSE
    RETURN 'Invalid action specified.';
  END IF;
END;
$$;

-- For process_withdraw_request
DROP FUNCTION IF EXISTS process_withdraw_request(integer, text);
CREATE OR REPLACE FUNCTION process_withdraw_request(p_tx_id integer, p_action text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  tx_user_id UUID;   -- Changed from INT to UUID
  tx_amount INTEGER;
  user_wallet_balance INTEGER;
BEGIN
  SELECT user_id, amount INTO tx_user_id, tx_amount
  FROM public.transactions WHERE id = p_tx_id AND type = 'withdraw' AND status = 'pending';

  IF NOT FOUND THEN RETURN 'Withdraw request not found or already processed.'; END IF;

  SELECT wallet_balance INTO user_wallet_balance FROM public.users WHERE id = tx_user_id;

  IF p_action = 'approve' THEN
    IF user_wallet_balance >= tx_amount THEN
      UPDATE public.transactions SET status = 'success' WHERE id = p_tx_id;
      UPDATE public.users SET wallet_balance = wallet_balance - tx_amount WHERE id = tx_user_id;
      RETURN 'Withdraw approved.';
    ELSE
      UPDATE public.transactions SET status = 'failed' WHERE id = p_tx_id;
      RETURN 'Withdraw rejected due to insufficient balance.';
    END IF;
  ELSIF p_action = 'reject' THEN
    UPDATE public.transactions SET status = 'failed' WHERE id = p_tx_id;
    RETURN 'Withdraw request rejected.';
  ELSE
    RETURN 'Invalid action specified.';
  END IF;
END;
$$;

-- For update_user_status
-- We change the user ID parameter from INT to UUID.
DROP FUNCTION IF EXISTS update_user_status(integer, text);
CREATE OR REPLACE FUNCTION update_user_status(p_user_id UUID, p_action text) -- Changed from INT to UUID
RETURNS text LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF p_action <> 'active' AND p_action <> 'blocked' THEN
    RETURN 'Invalid action specified.';
  END IF;

  UPDATE public.users
  SET status = p_action
  WHERE id = p_user_id;

  IF FOUND THEN
    RETURN 'User #' || p_user_id || ' has been ' || p_action;
  ELSE
    RETURN 'User not found.';
  END IF;
END;
$$;

SELECT 'Database schema and functions updated successfully!';
