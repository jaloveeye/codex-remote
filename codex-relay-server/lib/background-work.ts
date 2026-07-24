import { waitUntil } from "@vercel/functions";

export type BackgroundScheduler = (promise: Promise<unknown>) => void;

export function scheduleBackground(
  task: () => Promise<void>,
  scheduler: BackgroundScheduler = waitUntil
): void {
  const promise = Promise.resolve()
    .then(task)
    .catch((error) => {
      console.warn("[background] task failed:", error);
    });

  try {
    scheduler(promise);
  } catch (error) {
    // Local/unit environments may not expose a Vercel request context.
    // The promise has already started, so keep the request path non-blocking.
    console.warn("[background] waitUntil unavailable; continuing best-effort:", error);
  }
}
