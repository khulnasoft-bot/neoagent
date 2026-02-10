import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';

const cwd = process.cwd();

try {
  console.log('[v0] Starting TypeScript build process...');
  
  // Run the complete build command from package.json
  // Build: pnpm canvas:a2ui:bundle && tsdown && pnpm build:plugin-sdk:dts && node --import tsx scripts/write-plugin-sdk-entry-dts.ts && node --import tsx scripts/canvas-a2ui-copy.ts && node --import tsx scripts/copy-hook-metadata.ts && node --import tsx scripts/write-build-info.ts && node --import tsx scripts/write-cli-compat.ts
  
  // Start with tsdown which is the main TypeScript compiler
  console.log('[v0] Running tsdown...');
  execSync('pnpm exec tsdown', { cwd, stdio: 'inherit' });
  
  console.log('[v0] TypeScript build completed successfully!');
  console.log('[v0] dist directory has been generated.');
  
} catch (error) {
  console.error('[v0] Build failed:', error.message);
  process.exit(1);
}
