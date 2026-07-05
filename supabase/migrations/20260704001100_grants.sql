-- Blue Wagon — Step 2: explicit table/function grants.
-- Current Supabase Postgres images no longer grant DML on new public tables to
-- client roles by default (only TRUNCATE/REFERENCES/TRIGGER/MAINTAIN), and
-- default EXECUTE on functions is revoked. Grants are the coarse layer; RLS
-- policies remain the row-level gate on top.
--
--   anon           — read-only (catalog browsing; guest writes go through
--                    server routes using the service role)
--   authenticated  — full DML, row-scoped by RLS
--   service_role   — everything (server-side; bypasses RLS)

grant usage on schema public to anon, authenticated, service_role;

grant select on all tables in schema public to anon;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant all on all tables in schema public to service_role;

-- RLS policies invoke these as the querying role.
grant execute on function public.is_admin() to anon, authenticated, service_role;
grant execute on function public.is_owner() to anon, authenticated, service_role;

-- tables/functions created by future migrations (applied as postgres) inherit
-- the same grants.
alter default privileges for role postgres in schema public
  grant select on tables to anon;
alter default privileges for role postgres in schema public
  grant select, insert, update, delete on tables to authenticated;
alter default privileges for role postgres in schema public
  grant all on tables to service_role;
alter default privileges for role postgres in schema public
  grant execute on functions to anon, authenticated, service_role;
