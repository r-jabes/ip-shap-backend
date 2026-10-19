# Catalogue search strategy

## Chosen approach

**Postgres `pg_trgm` + `unaccent`**, not `tsvector` full-text search.

| Concern           | Choice                                                                 |
| ----------------- | ---------------------------------------------------------------------- |
| Case / accents    | `lower(unaccent(...))` via `catalogue_search_normalize`                |
| Matching          | `ILIKE '%'                                                             |     | q   |     | '%'`and/or`similarity(name, q) > threshold` |
| Indexes           | GIN trigram on `products.name` and generated `search_document`         |
| Ranking           | Prefer exact/prefix then trigram similarity; keep UI sort as tie-break |
| Public visibility | Always `status = 'published'` in the same query                        |

## Why not FTS (yet)

- Catalogue queries are short brand/product tokens, not long documents.
- Trigram handles partial SKU/brand typing and accented labels well.
- FTS dictionaries add complexity without clear gain at 300–few-thousand SKUs.

## Limits

- Not semantic / synonym search (“vodka” ≠ “spirit” unless in the text).
- Very short queries (`a`, `1`) can over-match — enforce `q` length ≥ 2 in the app for trigram ranking paths.
- Query params are bounded (`q` ≤ 120 chars, `pageSize` ≤ 48) to protect the API.
- Demo-mode frontend uses the same normalization helper in TypeScript against fixtures; production uses SQL.

## Example public list SQL (reference)

```sql
select p.*
from public.products p
left join public.categories c on c.id = p.category_id
left join public.brands b on b.id = p.brand_id
where p.status = 'published'
  and ($1::text is null or c.slug = $1)
  and ($2::text is null or b.slug = $2)
  and (
    $3::text is null
    or public.catalogue_search_normalize(p.name) like '%' || public.catalogue_search_normalize($3) || '%'
    or public.catalogue_search_normalize(p.description) like '%' || public.catalogue_search_normalize($3) || '%'
    or public.catalogue_search_normalize(b.name) like '%' || public.catalogue_search_normalize($3) || '%'
  )
order by p.name asc
limit $4 offset $5;
```

Inspect `explain analyse` with ~300–1000 rows before launch; adjust threshold / indexes if sequential scans dominate.
