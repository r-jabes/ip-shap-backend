-- P7: public catalogue suggest via pg_trgm / unaccent (published only).

create or replace function public.suggest_catalogue(
  p_query text,
  p_limit integer default 6
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  q text;
  lim integer;
  result jsonb;
begin
  q := trim(coalesce(p_query, ''));
  if char_length(q) < 2 or char_length(q) > 80 then
    return '[]'::jsonb;
  end if;

  lim := least(greatest(coalesce(p_limit, 6), 1), 12);

  select coalesce(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb)
  into result
  from (
    select
      p.id,
      p.slug,
      p.name,
      coalesce(b.name, '') as brand_name,
      p.price_rwf,
      img.src as image_src,
      coalesce(img.alt, p.name) as image_alt,
      (
        case
          when public.catalogue_search_normalize(p.name) like public.catalogue_search_normalize(q) || '%' then 100
          when public.catalogue_search_normalize(p.name) like '% ' || public.catalogue_search_normalize(q) || '%' then 80
          when public.catalogue_search_normalize(p.name) like '%' || public.catalogue_search_normalize(q) || '%' then 60
          when public.catalogue_search_normalize(coalesce(b.name, '')) like '%' || public.catalogue_search_normalize(q) || '%' then 40
          when public.catalogue_search_normalize(coalesce(c.name, '')) like '%' || public.catalogue_search_normalize(q) || '%' then 30
          else greatest(similarity(public.catalogue_search_normalize(p.name), public.catalogue_search_normalize(q)) * 50, 1)
        end
      )::real as score
    from public.products p
    left join public.brands b on b.id = p.brand_id
    left join public.categories c on c.id = p.category_id
    left join lateral (
      select pi.src, pi.alt
      from public.product_images pi
      where pi.product_id = p.id
        and pi.processing_status in ('needs_review', 'approved_for_catalogue')
      order by pi.sort_order asc
      limit 1
    ) img on true
    where p.status = 'published'
      and (
        public.catalogue_search_normalize(p.name) like '%' || public.catalogue_search_normalize(q) || '%'
        or public.catalogue_search_normalize(coalesce(p.description, '')) like '%' || public.catalogue_search_normalize(q) || '%'
        or public.catalogue_search_normalize(coalesce(b.name, '')) like '%' || public.catalogue_search_normalize(q) || '%'
        or public.catalogue_search_normalize(coalesce(c.name, '')) like '%' || public.catalogue_search_normalize(q) || '%'
        or similarity(public.catalogue_search_normalize(p.name), public.catalogue_search_normalize(q)) > 0.2
      )
    order by score desc, p.name asc
    limit lim
  ) t;

  return result;
end;
$$;

revoke all on function public.suggest_catalogue(text, integer) from public;
grant execute on function public.suggest_catalogue(text, integer) to anon, authenticated, service_role;

comment on function public.suggest_catalogue(text, integer) is
  'P7 rate-limited suggest: published products only, trigram/unaccent matching.';
