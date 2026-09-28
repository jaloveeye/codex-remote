import type { Session } from "./types.js";

export async function reuseOrLoadSession(
  existing: Session | undefined,
  loader: () => Promise<Session | null>
): Promise<Session | null> {
  return existing ?? loader();
}

export async function reuseOrLoadMobileDeviceIds(
  existing: readonly string[] | undefined,
  loader: () => Promise<readonly string[]>
): Promise<readonly string[]> {
  return existing ?? loader();
}
