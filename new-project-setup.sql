-- TeamDynamix Release Notes - Supabase new project bootstrap
-- Run this in the target Supabase SQL editor.

create extension if not exists pgcrypto;

-- Keep updated_at current when rows change.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.release_notes (
  id text primary key,
  release text,
  version text,
  date date,
  product text,
  source text,
  source_file text,
  imported_at timestamptz,
  section_num integer,
  category text,
  title text,
  body_html text,
  body_text text,
  has_day_one_impact boolean default false,
  parent_section text,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.app_config (
  key text primary key,
  value text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_release_notes_date on public.release_notes (date desc);
create index if not exists idx_release_notes_updated_at on public.release_notes (updated_at desc);

-- Triggers (idempotent)
do $$
begin
  if not exists (
    select 1 from pg_trigger
    where tgname = 'trg_release_notes_updated_at'
  ) then
    create trigger trg_release_notes_updated_at
    before update on public.release_notes
    for each row execute function public.set_updated_at();
  end if;

  if not exists (
    select 1 from pg_trigger
    where tgname = 'trg_app_config_updated_at'
  ) then
    create trigger trg_app_config_updated_at
    before update on public.app_config
    for each row execute function public.set_updated_at();
  end if;
end
$$;

alter table public.release_notes enable row level security;
alter table public.app_config enable row level security;

-- release_notes policies
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'release_notes' AND policyname = 'release_notes_select'
  ) THEN
    CREATE POLICY release_notes_select ON public.release_notes
      FOR SELECT TO anon, authenticated
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'release_notes' AND policyname = 'release_notes_insert'
  ) THEN
    CREATE POLICY release_notes_insert ON public.release_notes
      FOR INSERT TO anon, authenticated
      WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'release_notes' AND policyname = 'release_notes_update'
  ) THEN
    CREATE POLICY release_notes_update ON public.release_notes
      FOR UPDATE TO anon, authenticated
      USING (true)
      WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'release_notes' AND policyname = 'release_notes_delete'
  ) THEN
    CREATE POLICY release_notes_delete ON public.release_notes
      FOR DELETE TO anon, authenticated
      USING (true);
  END IF;
END
$$;

-- app_config policies
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'app_config' AND policyname = 'app_config_select'
  ) THEN
    CREATE POLICY app_config_select ON public.app_config
      FOR SELECT TO anon, authenticated
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'app_config' AND policyname = 'app_config_insert'
  ) THEN
    CREATE POLICY app_config_insert ON public.app_config
      FOR INSERT TO anon, authenticated
      WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'app_config' AND policyname = 'app_config_update'
  ) THEN
    CREATE POLICY app_config_update ON public.app_config
      FOR UPDATE TO anon, authenticated
      USING (true)
      WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'app_config' AND policyname = 'app_config_delete'
  ) THEN
    CREATE POLICY app_config_delete ON public.app_config
      FOR DELETE TO anon, authenticated
      USING (true);
  END IF;
END
$$;

-- Storage bucket used for extracted images.
insert into storage.buckets (id, name, public)
values ('release-note-images', 'release-note-images', true)
on conflict (id) do nothing;

-- storage.objects policies scoped to this bucket
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'release_note_images_select'
  ) THEN
    CREATE POLICY release_note_images_select ON storage.objects
      FOR SELECT TO anon, authenticated
      USING (bucket_id = 'release-note-images');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'release_note_images_insert'
  ) THEN
    CREATE POLICY release_note_images_insert ON storage.objects
      FOR INSERT TO anon, authenticated
      WITH CHECK (bucket_id = 'release-note-images');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'release_note_images_update'
  ) THEN
    CREATE POLICY release_note_images_update ON storage.objects
      FOR UPDATE TO anon, authenticated
      USING (bucket_id = 'release-note-images')
      WITH CHECK (bucket_id = 'release-note-images');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'release_note_images_delete'
  ) THEN
    CREATE POLICY release_note_images_delete ON storage.objects
      FOR DELETE TO anon, authenticated
      USING (bucket_id = 'release-note-images');
  END IF;
END
$$;
