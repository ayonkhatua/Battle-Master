-- ========= FUNCTION 1: PROCESS DEPOSIT REQUEST =========
-- This function handles approving or rejecting a coin deposit request.
create or replace function process_deposit_request(p_tx_id int, p_action text) -- p_action should be 'approve' or 'reject'
returns text
language plpgsql
security definer
as $$
declare
  v_tx transactions;
  v_status text;
begin
  -- 1. Find the pending deposit transaction
  select * into v_tx from public.transactions where id = p_tx_id and type = 'deposit' and status = 'pending';

  if v_tx is null then
    return 'Transaction not found or already processed.';
  end if;

  -- 2. Determine the new status and perform actions
  if p_action = 'approve' then
    -- Add coins to user's wallet
    update public.users
    set wallet_balance = wallet_balance + v_tx.amount,
        deposited = deposited + v_tx.amount
    where id = v_tx.user_id;

    v_status := 'approved';
  elsif p_action = 'reject' then
    v_status := 'rejected';
  else
    return 'Invalid action.';
  end if;

  -- 3. Update the transaction status
  update public.transactions set status = v_status where id = p_tx_id;

  return 'Transaction #' || p_tx_id || ' has been ' || v_status;
end;
$$;

-- ========= FUNCTION 2: PROCESS WITHDRAW REQUEST =========
-- This function handles approving or rejecting a withdrawal request.
create or replace function process_withdraw_request(p_tx_id int, p_action text) -- p_action should be 'approve' or 'reject'
returns text
language plpgsql
security definer
as $$
declare
  v_tx transactions;
  v_user users;
  v_status text;
begin
  -- 1. Find the pending withdraw transaction and the corresponding user
  select * into v_tx from public.transactions where id = p_tx_id and type = 'withdraw' and status = 'pending';

  if v_tx is null then
    return 'Transaction not found or already processed.';
  end if;

  select * into v_user from public.users where id = v_tx.user_id;

  -- 2. Determine the new status and perform actions
  if p_action = 'approve' then
    -- Check if user has enough balance
    if v_user.wallet_balance >= v_tx.amount then
      -- Deduct coins from user's wallet
      update public.users
      set wallet_balance = wallet_balance - v_tx.amount
      where id = v_tx.user_id;

      v_status := 'approved';
    else
      -- Not enough balance, mark transaction as failed
      v_status := 'failed';
    end if;

  elsif p_action = 'reject' then
    v_status := 'rejected';
  else
    return 'Invalid action.';
  end if;

  -- 3. Update the transaction status
  update public.transactions set status = v_status where id = p_tx_id;

  return 'Transaction #' || p_tx_id || ' has been ' || v_status;
end;
$$;