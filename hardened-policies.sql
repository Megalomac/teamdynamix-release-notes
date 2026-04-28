-- TeamDynamix Release Notes - hardened RLS/policy pass
-- Run this AFTER new-project-setup.sql.
-- Goal: keep app compatibility while reducing policy blast radius.

begin;

-- Ensure RLS remains enabled.
alter table public.release_notes enable row level security;
alter table public.app_config enable row level security;

-- Optional server-side write switch for anon/authenticated writers.
-- Set to false to block INSERT/UPDATE/DELETE in release_notes without changing app code.
insert into public.app_config (key, value)
values ('write_enabled', 'true')
on conflict (key) do nothing;

-- Remove broad baseline policies if they exist.
do $$
begin
  if exists (select 1 from pg_policies where schemaname='public' and tablename='release_notes' and policyname='release_notes_select') then
    execute 'drop policy release_notes_select on public.release_notes';
  end if;
  if exists (select 1 from pg_policies where schemaname='public' and tablename='release_notes' and policyname='release_notes_insert') then
    execute 'drop policy release_notes_insert on public.release_notes';
  end if;
  if exists (select 1 from pg_policies where schemaname='public' and tablename='release_notes' and policyname='release_notes_update') then
    execute 'drop policy release_notes_update on public.release_notes';
  end if;
  if exists (select 1 from pg_policies where schemaname='public' and tablename='release_notes' and policyname='release_notes_delete') then
    execute 'drop policy release_notes_delete on public.release_notes';
  end if;

  if exists (select 1 from pg_policies where schemaname='public' and tablename='app_config' and policyname='app_config_select') then
    execute 'drop policy app_config_select on public.app_config';
  end if;
  if exists (select 1 from pg_policies where schemaname='public' and tablename='app_config' and policyname='app_config_insert') then
    execute 'drop policy app_config_insert on public.app_config';
  end if;
  if exists (select 1 from pg_policies where schemaname='public' and tablename='app_config' and policyname='app_config_update') then
    execute 'drop policy app_config_update on public.app_config';
  end if;
  if exists (select 1 from pg_policies where schemaname='public' and tablename='app_config' and policyname='app_config_delete') then
    execute 'drop policy app_config_delete on public.app_config';
  end if;

  if exists (select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='release_note_images_select') then
    execute 'drop policy release_note_images_select on storage.objects';
  end if;
  if exists (select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='release_note_images_insert') then
    execute 'drop policy release_note_images_insert on storage.objects';
  end if;
  if exists (select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='release_note_images_update') then
    execute 'drop policy release_note_images_update on storage.objects';
  end if;
  if exists (select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='release_note_images_delete') then
    execute 'drop policy release_note_images_delete on storage.objects';
  end if;
end
$$;

-- release_notes policies: still app-compatible, but gated by write_enabled=true for mutating operations.
drop policy if exists release_notes_select_all on public.release_notes;
drop policy if exists release_notes_insert_when_enabled on public.release_notes;
drop policy if exists release_notes_update_when_enabled on public.release_notes;
drop policy if exists release_notes_delete_when_enabled on public.release_notes;

create policy release_notes_select_all on public.release_notes
  for select to anon, authenticated
  using (true);

create policy release_notes_insert_when_enabled on public.release_notes
  for insert to anon, authenticated
  with check (
    exists (
      select 1
      from public.app_config cfg
      where cfg.key = 'write_enabled'
        and lower(coalesce(cfg.value, 'false')) = 'true'
    )
    and id is not null
    and length(id) between 4 and 128
  );

create policy release_notes_update_when_enabled on public.release_notes
  for update to anon, authenticated
  using (
    exists (
      select 1
      from public.app_config cfg
      where cfg.key = 'write_enabled'
        and lower(coalesce(cfg.value, 'false')) = 'true'
    )
  )
  with check (
    exists (
      select 1
      from public.app_config cfg
      where cfg.key = 'write_enabled'
        and lower(coalesce(cfg.value, 'false')) = 'true'
    )
    and id is not null
    and length(id) between 4 and 128
  );

create policy release_notes_delete_when_enabled on public.release_notes
  for delete to anon, authenticated
  using (
    exists (
      select 1
      from public.app_config cfg
      where cfg.key = 'write_enabled'
        and lower(coalesce(cfg.value, 'false')) = 'true'
    )
  );

-- app_config policies: restrict visible/mutable keys to app needs.
drop policy if exists app_config_select_known_keys on public.app_config;
drop policy if exists app_config_insert_known_keys on public.app_config;
drop policy if exists app_config_update_known_keys on public.app_config;
drop policy if exists app_config_delete_healthcheck_only on public.app_config;

create policy app_config_select_known_keys on public.app_config
  for select to anon, authenticated
  using (key in ('passcode_hash', 'write_enabled') or key like 'healthcheck-%');

create policy app_config_insert_known_keys on public.app_config
  for insert to anon, authenticated
  with check (key in ('passcode_hash', 'write_enabled') or key like 'healthcheck-%');

create policy app_config_update_known_keys on public.app_config
  for update to anon, authenticated
  using (key in ('passcode_hash', 'write_enabled') or key like 'healthcheck-%')
  with check (key in ('passcode_hash', 'write_enabled') or key like 'healthcheck-%');

-- Keep health check compatibility: allow deleting transient healthcheck rows only.
create policy app_config_delete_healthcheck_only on public.app_config
  for delete to anon, authenticated
  using (key like 'healthcheck-%');

-- Storage policies: keep bucket scoping and basic object-name sanity checks.
drop policy if exists release_note_images_select on storage.objects;
drop policy if exists release_note_images_insert on storage.objects;
drop policy if exists release_note_images_update on storage.objects;
drop policy if exists release_note_images_delete on storage.objects;

create policy release_note_images_select on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'release-note-images');

create policy release_note_images_insert on storage.objects
  for insert to anon, authenticated
  with check (
    bucket_id = 'release-note-images'
    and length(name) between 3 and 240
    and position('..' in name) = 0
  );

create policy release_note_images_update on storage.objects
  for update to anon, authenticated
  using (
    bucket_id = 'release-note-images'
    and length(name) between 3 and 240
    and position('..' in name) = 0
  )
  with check (
    bucket_id = 'release-note-images'
    and length(name) between 3 and 240
    and position('..' in name) = 0
  );

create policy release_note_images_delete on storage.objects
  for delete to anon, authenticated
  using (
    bucket_id = 'release-note-images'
    and length(name) between 3 and 240
    and position('..' in name) = 0
  );

commit;
