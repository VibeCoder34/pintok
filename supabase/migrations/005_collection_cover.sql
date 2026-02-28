-- Optional cover image for a collection. When set, shown on journey cards; otherwise first pin image is used.
alter table public.collections
  add column if not exists cover_image_url text;

comment on column public.collections.cover_image_url is 'Optional cover image URL. When null/empty, UI falls back to first pin image in the collection.';
