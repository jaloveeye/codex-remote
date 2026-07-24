import { existsSync, readdirSync } from "node:fs";
import { join, relative } from "node:path";

const functionsRoot = join(process.cwd(), ".vercel", "output", "functions");

function findFunctionDirectories(directory) {
  if (!existsSync(directory)) {
    return [];
  }

  const matches = [];
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    if (!entry.isDirectory()) {
      continue;
    }

    const path = join(directory, entry.name);
    if (entry.name.endsWith(".func")) {
      matches.push(path);
      continue;
    }
    matches.push(...findFunctionDirectories(path));
  }
  return matches;
}

const functionDirectories = findFunctionDirectories(functionsRoot);
if (functionDirectories.length !== 1) {
  const names = functionDirectories.map((path) =>
    relative(functionsRoot, path)
  );
  console.error(
    `[FAIL] expected exactly one Vercel function, found ${functionDirectories.length}`,
    names
  );
  process.exit(1);
}

console.log(
  `[OK] exactly one Vercel function: ${relative(
    functionsRoot,
    functionDirectories[0]
  )}`
);
