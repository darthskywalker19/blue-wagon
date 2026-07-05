-- Blue Wagon — Step 2: shared helpers
-- Every table carries created_at/updated_at; this trigger keeps updated_at current.

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
