import { z } from "zod";

const envSchema = z.object({
  SUPABASE_URL: z.string().url().optional(),
  SUPABASE_ANON_KEY: z.string().min(1).optional(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1).optional(),
  SUPABASE_DB_URL: z.string().min(1).optional(),
  /** `unselected` until a Rwanda merchant provider is verified; `sandbox` for tests only. */
  PAYMENT_PROVIDER: z.enum(["unselected", "sandbox"]).default("unselected"),
  PAYMENT_WEBHOOK_SECRET: z.string().min(16).optional(),
  NODE_ENV: z
    .enum(["development", "test", "production"])
    .default("development"),
});

export type BackendEnv = z.infer<typeof envSchema>;

export function parseBackendEnv(
  source: NodeJS.ProcessEnv = process.env,
): BackendEnv {
  return envSchema.parse({
    SUPABASE_URL: source.SUPABASE_URL,
    SUPABASE_ANON_KEY: source.SUPABASE_ANON_KEY,
    SUPABASE_SERVICE_ROLE_KEY: source.SUPABASE_SERVICE_ROLE_KEY,
    SUPABASE_DB_URL: source.SUPABASE_DB_URL,
    PAYMENT_PROVIDER: source.PAYMENT_PROVIDER ?? "unselected",
    PAYMENT_WEBHOOK_SECRET: source.PAYMENT_WEBHOOK_SECRET,
    NODE_ENV: source.NODE_ENV,
  });
}
