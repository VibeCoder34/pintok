-- Store cover color (hex without #) for collection cards when no cover image.
-- Used as background/gradient on the collection card in the UI.
alter table public.collections
add column if not exists cover_color text;

comment on column public.collections.cover_color is 'Hex color (e.g. 5E35B1) for card background when cover_image_url is empty';
