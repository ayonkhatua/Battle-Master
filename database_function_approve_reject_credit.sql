-- ========= FUNCTION: APPROVE/REJECT CREDIT REQUEST =========
-- This function handles the approval or rejection of a credit transaction.
CREATE OR REPLACE FUNCTION approve_reject_credit(p_tx_id integer, p_action text) -- p_action should be 'approve' or 'reject'
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  tx_record RECORD;
BEGIN
  -- 1. Find the transaction and lock the row
  SELECT * INTO tx_record
  FROM public.transactions
  WHERE id = p_tx_id AND type = 'credit' AND status = 'pending'
  FOR UPDATE;

  -- 2. Check if the transaction exists and is pending
  IF NOT FOUND THEN
    RETURN 'Transaction not found or already processed.';
  END IF;

  -- 3. Process the action
  IF p_action = 'approve' THEN
    -- Update transaction status to 'approved'
    UPDATE public.transactions SET status = 'approved' WHERE id = p_tx_id;

    -- Add the amount to the user's wallet balance
    UPDATE public.users SET wallet_balance = wallet_balance + tx_record.amount WHERE id = tx_record.user_id;

    RETURN 'Request approved. User wallet has been credited.';

  ELSIF p_action = 'reject' THEN
    -- Update transaction status to 'rejected'
    UPDATE public.transactions SET status = 'rejected' WHERE id = p_tx_id;

    RETURN 'Request has been rejected.';
  ELSE
    RETURN 'Invalid action specified. Please use \'approve\' or \'reject\'.';
  END IF;

END;
$$;