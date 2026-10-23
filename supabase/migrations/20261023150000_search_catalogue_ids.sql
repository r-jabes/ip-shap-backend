-- Shop search: ids of published products matching free text.
-- Same matching rules as suggest_catalogue (accent-insensitive containment on name, description,
-- brand and category, plus trigram similarity on the name so small typos still find the product),
-- but returns ids only. The storefront intersects them with its cached catalogue index, so a
-- search no longer needs to load every product.

create or replace function public.search_catalogue_ids(p_query text)
returns uuid[]
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  q text;
  result uuid[];
begin
  q := public.catalogue_search_normalize(trim(coalesce(p_query, '')));
  if char_length(q) < 2 or char_length(q) > 80 then
    return '{}'::uuid[];
  end if;

  select coalesce(array_agg(t.id), '{}'::uuid[])
  into result
  from (
    select p.id
    from public.products p
    left join public.brands b on b.id = p.brand_id
    left join public.categories c on c.id = p.category_id
    where p.status = 'published'
      and (
        public.catalogue_search_normalize(p.name) like '%' || q || '%'
        or public.catalogue_search_normalize(coalesce(p.description, '')) like '%' || q || '%'
        or public.catalogue_search_normalize(coalesce(b.name, '')) like '%' || q || '%'
        or public.catalogue_search_normalize(coalesce(c.name, '')) like '%' || q || '%'
        or similarity(public.catalogue_search_normalize(p.name), q) > 0.3
      )
    limit 2000
  ) t;

  return result;
end;
$$;

revoke all on function public.search_catalogue_ids(text) from public;
grant execute on function public.search_catalogue_ids(text) to anon, authenticated, service_role;

comment on function public.search_catalogue_ids(text) is
  'Shop search: published product ids matching text, accent-insensitive with typo tolerance.';
