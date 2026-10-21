/**
 * Create Auth users + owner admin_profiles from env (staging bootstrap).
 *
 * Requires: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
 * Owners: ADMIN_OWNER_1_EMAIL, ADMIN_OWNER_1_PASSWORD, ADMIN_OWNER_1_NAME (optional)
 *         ADMIN_OWNER_2_… (same pattern; add _3 if needed)
 *
 * Usage (from backend/):
 *   node --env-file=.env.local scripts/seed-admins.mjs
 *   npm run db:seed:admins
 */
import { createClient } from "@supabase/supabase-js";

function loadOwners() {
  const owners = [];
  for (let i = 1; i <= 10; i += 1) {
    const email = process.env[`ADMIN_OWNER_${i}_EMAIL`]?.trim();
    const password = process.env[`ADMIN_OWNER_${i}_PASSWORD`];
    if (!email && !password) continue;
    if (!email || !password || password.length < 8) {
      throw new Error(
        `ADMIN_OWNER_${i}_EMAIL and ADMIN_OWNER_${i}_PASSWORD (≥ 8 chars) are required together.`,
      );
    }
    owners.push({
      email: email.toLowerCase(),
      password,
      name: process.env[`ADMIN_OWNER_${i}_NAME`]?.trim() || email.split("@")[0],
    });
  }
  return owners;
}

async function findUserIdByEmail(supabase, email) {
  // Paginate lightly — fine for staging bootstrap.
  for (let page = 1; page <= 20; page += 1) {
    const { data, error } = await supabase.auth.admin.listUsers({
      page,
      perPage: 200,
    });
    if (error) throw error;
    const match = data.users.find(
      (u) => u.email?.toLowerCase() === email.toLowerCase(),
    );
    if (match) return match.id;
    if (data.users.length < 200) return null;
  }
  return null;
}

async function ensureAuthUser(supabase, owner) {
  const { data, error } = await supabase.auth.admin.createUser({
    email: owner.email,
    password: owner.password,
    email_confirm: true,
    user_metadata: { display_name: owner.name },
  });

  if (!error && data.user) {
    return { userId: data.user.id, created: true };
  }

  const already =
    error?.message?.toLowerCase().includes("already") ||
    error?.message?.toLowerCase().includes("registered") ||
    error?.status === 422;

  if (!already) {
    throw error ?? new Error(`Failed to create ${owner.email}`);
  }

  const existingId = await findUserIdByEmail(supabase, owner.email);
  if (!existingId) {
    throw new Error(
      `User ${owner.email} appears to exist but could not be resolved by email.`,
    );
  }

  const { error: updateError } = await supabase.auth.admin.updateUserById(
    existingId,
    { password: owner.password, email_confirm: true },
  );
  if (updateError) throw updateError;

  return { userId: existingId, created: false };
}

async function ensureOwnerProfile(supabase, userId, displayName) {
  const { error } = await supabase.from("admin_profiles").upsert(
    {
      user_id: userId,
      role: "owner",
      display_name: displayName,
      is_active: true,
    },
    { onConflict: "user_id" },
  );
  if (error) throw error;
}

async function main() {
  const url = process.env.SUPABASE_URL?.trim();
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY?.trim();
  if (!url || !serviceKey) {
    throw new Error("Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env.local");
  }

  const owners = loadOwners();
  if (owners.length === 0) {
    throw new Error(
      "No owners configured. Set ADMIN_OWNER_1_EMAIL / ADMIN_OWNER_1_PASSWORD (and _2…).",
    );
  }

  const supabase = createClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  for (const owner of owners) {
    const { userId, created } = await ensureAuthUser(supabase, owner);
    await ensureOwnerProfile(supabase, userId, owner.name);
    console.log(
      JSON.stringify({
        email: owner.email,
        userId,
        role: "owner",
        auth: created ? "created" : "updated",
        profile: "upserted",
      }),
    );
  }
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});
