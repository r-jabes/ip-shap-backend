-- Common drinks categories for the IP SHAP catalogue.
-- Idempotent: existing categories (and any edits made in admin) are left untouched.
-- Apply: npm run db:seed:categories

insert into public.categories (slug, name, description)
values
  ('whisky', 'Whisky', 'Scotch, bourbon and other whiskies.'),
  ('vodka', 'Vodka', 'Plain and flavoured vodka.'),
  ('gin', 'Gin', 'London dry, flavoured and craft gin.'),
  ('rum', 'Rum', 'White, gold and dark rum.'),
  ('brandy-cognac', 'Brandy & Cognac', 'Brandy, cognac and armagnac.'),
  ('tequila', 'Tequila', 'Blanco, reposado and añejo tequila.'),
  ('liqueurs', 'Liqueurs', 'Cream, fruit and herbal liqueurs.'),
  ('wine', 'Wine', 'Red, white and sparkling.'),
  ('red-wine', 'Red wine', 'Still reds for the table.'),
  ('white-wine', 'White wine', 'Crisp and aromatic whites.'),
  ('rose-wine', 'Rosé wine', 'Dry and off-dry rosé.'),
  ('sparkling-wine', 'Sparkling wine', 'Sparkling wine, prosecco and champagne.'),
  ('beer-cider', 'Beer & Cider', 'Lagers, ales and ciders.'),
  ('soft-drinks', 'Soft drinks & Mixers', 'Sodas, tonics, juices and water.')
on conflict (slug) do nothing;
