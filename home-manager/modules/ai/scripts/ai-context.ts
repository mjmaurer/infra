#!/usr/bin/env bun

import { readFile, stat } from "fs/promises";
import { basename, resolve } from "path";

async function main(): Promise<void> {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.error("Usage: ai-context <file> [file...]");
    process.exit(1);
  }

  for (const filePath of args) {
    const resolved = resolve(filePath);
    const name = basename(resolved);

    try {
      const [content, info] = await Promise.all([
        readFile(resolved, "utf-8"),
        stat(resolved),
      ]);

      const lines = content.split("\n").length;
      const sizeKb = (info.size / 1024).toFixed(1);

      console.log(`--- ${name} ---`);
      console.log(`Path:  ${resolved}`);
      console.log(`Size:  ${sizeKb} KB`);
      console.log(`Lines: ${lines}`);
      console.log(`Modified: ${info.mtime.toISOString()}`);
      console.log("");
      console.log(content);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      console.error(`Error reading ${filePath}: ${message}`);
      process.exit(1);
    }
  }
}

main();
