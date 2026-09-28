import { readFileSync } from "node:fs";
import { join } from "node:path";

const configPath = join(process.cwd(), "vercel.json");
const config = JSON.parse(readFileSync(configPath, "utf8"));
const regions = Array.isArray(config.regions) ? config.regions : [];

if (regions.length !== 1 || regions[0] !== "icn1") {
  console.error(
    `[FAIL] expected Vercel region ["icn1"], found ${JSON.stringify(regions)}`
  );
  process.exit(1);
}

console.log("[OK] Vercel function region is icn1");
