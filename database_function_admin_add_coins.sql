
-- This function allows an admin to add coins to a user's wallet securely.
-- It updates the user's balance and records a transaction in one atomic operation.

create or replace function admin_add_coins (
  p_user_id uuid,
  p_amount int,
  p_bucket text, -- Must be 'deposited', 'winning', or 'bonus'
  p_note text
)
returns void
language plpgsql
security definer -- Important: Allows the function to run with elevated privileges to modify tables
as $$
declare
  v_type text;
  v_description text;
begin
  -- 1. Validate the bucket type
  if p_bucket not in ('deposited', 'winning', 'bonus') then
    raise exception 'Invalid bucket type specified. Must be one of: deposited, winning, bonus.';
  end if;

  -- 2. Update the user's wallet balance and the specific bucket
  -- Using format() to safely inject the bucket column name
  execute format(
    'update public.users set wallet_balance = wallet_balance + %L, %I = %I + %L where id = %L',
    p_amount,
    p_bucket, -- column name
    p_bucket, -- column name
    p_amount,
    p_user_id
  );

  -- 3. Determine the transaction type for the log
  case p_bucket
    when 'deposited' then v_type := 'deposit';
    when 'winning' then v_type := 'winning';
    when 'bonus' then v_type := 'bonus';
  end case;

  v_description := 'Admin added coins (' || v_type || ')';
  if p_note is not null and p_note <> '' then
    v_description := v_description || ' - ' || p_note;
  end if;

  -- 4. Insert a record into the transactions table
  insert into public.transactions(user_id, amount, type, txn_ref, status)
  values (p_user_id, p_amount, v_type, v_description, 'approved');

end;
$$;
