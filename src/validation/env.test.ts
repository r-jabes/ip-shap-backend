import { describe, expect, it } from "vitest";
import { parseBackendEnv } from "./env.js";

describe("parseBackendEnv", () => {
  it("allows missing Supabase values during foundation setup", () => {
    const env = parseBackendEnv({ NODE_ENV: "test" });
    expect(env.NODE_ENV).toBe("test");
    expect(env.SUPABASE_URL).toBeUndefined();
  });

  it("rejects invalid Supabase URL when provided", () => {
    expect(() =>
      parseBackendEnv({
        NODE_ENV: "test",
        SUPABASE_URL: "not-a-url",
      }),
    ).toThrow();
  });
});
