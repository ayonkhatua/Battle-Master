-- ========= FUNCTION: UPDATE USER STATUS =========
-- This function updates a user's status to 'active' or 'blocked'.
create or replace function update_user_status(p_user_id int, p_action text) -- p_action should be 'active' or 'blocked'
returns text
language plpgsql
security definer
as $$
begin
  -- Check if the action is valid
  if p_action <> 'active' and p_action <> 'blocked' then
    return 'Invalid action specified.';
  end if;

  -- Update the user's status
  update public.users
  set status = p_action
  where id = p_user_id;

  if found then
    return 'User #' || p_user_id || ' has been ' || p_action;
  else
    return 'User not found.';
  end if;

end;
$$;