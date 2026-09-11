-- Audit Logging
--
-- Traces sensitive operations: realtor verification decisions, account
-- deletions, and role modifications. Additive migration; does not modify any
-- previously applied migration.

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.users (id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists audit_logs_actor_id_idx on public.audit_logs (actor_id);
create index if not exists audit_logs_entity_idx on public.audit_logs (entity_type, entity_id);
create index if not exists audit_logs_action_idx on public.audit_logs (action);
create index if not exists audit_logs_created_at_idx on public.audit_logs (created_at desc);

alter table public.audit_logs enable row level security;

-- Only admins may read the audit log. Writes happen via triggers (security
-- definer) or the service role, so no insert policy is granted to clients.
drop policy if exists "audit_logs_admin_select" on public.audit_logs;
create policy "audit_logs_admin_select"
  on public.audit_logs
  for select
  to authenticated
  using (
    exists (
      select 1 from public.users u
      where u.id = auth.uid() and u.role = 'admin'
    )
  );

-- Helper used by triggers and Edge Functions to record an audit entry.
create or replace function public.write_audit_log(
  p_actor_id uuid,
  p_action text,
  p_entity_type text,
  p_entity_id uuid,
  p_metadata jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.audit_logs (actor_id, action, entity_type, entity_id, metadata)
  values (p_actor_id, p_action, p_entity_type, p_entity_id, coalesce(p_metadata, '{}'::jsonb));
end;
$$;

-- Audit role modifications on users.
create or replace function public.audit_user_role_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.role is distinct from old.role then
    perform public.write_audit_log(
      auth.uid(),
      'role_modified',
      'user',
      new.id,
      jsonb_build_object('old_role', old.role, 'new_role', new.role)
    );
  end if;
  return new;
end;
$$;

drop trigger if exists trg_audit_user_role_change on public.users;
create trigger trg_audit_user_role_change
  after update on public.users
  for each row
  execute function public.audit_user_role_change();

-- Audit realtor verification decisions (approve/reject).
create or replace function public.audit_verification_decision()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status is distinct from old.status
     and new.status in ('approved', 'rejected') then
    perform public.write_audit_log(
      auth.uid(),
      'verification_' || new.status,
      'realtor_verification',
      new.id,
      jsonb_build_object(
        'realtor_id', new.realtor_id,
        'old_status', old.status,
        'new_status', new.status
      )
    );
  end if;
  return new;
end;
$$;

drop trigger if exists trg_audit_verification_decision on public.realtor_verifications;
create trigger trg_audit_verification_decision
  after update on public.realtor_verifications
  for each row
  execute function public.audit_verification_decision();

-- Audit account deletions. The row is captured before deletion so the actor
-- and entity id are still available.
create or replace function public.audit_user_deletion()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.write_audit_log(
    auth.uid(),
    'account_deleted',
    'user',
    old.id,
    jsonb_build_object('email', old.email, 'role', old.role)
  );
  return old;
end;
$$;

drop trigger if exists trg_audit_user_deletion on public.users;
create trigger trg_audit_user_deletion
  before delete on public.users
  for each row
  execute function public.audit_user_deletion();

-- Only the service role may call the helper directly.
revoke all on function public.write_audit_log(uuid, text, text, uuid, jsonb) from public;
grant execute on function public.write_audit_log(uuid, text, text, uuid, jsonb) to service_role;
