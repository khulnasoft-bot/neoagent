#!/bin/bash
# Vercel deployment build script
# This script handles native module building for production deployment

set -e

echo "[Vercel Build] Starting build process..."

# Install dependencies with scripts disabled
echo "[Vercel Build] Installing dependencies..."
pnpm install --frozen-lockfile --ignore-scripts

# Run selective postinstall hooks for essential packages only
echo "[Vercel Build] Running selective postinstall scripts..."

# sharp and esbuild need to compile native modules
if [ -d "node_modules/sharp" ]; then
  echo "[Vercel Build] Building sharp..."
  cd node_modules/sharp && npm run install || true && cd ../..
fi

if [ -d "node_modules/esbuild" ]; then
  echo "[Vercel Build] Building esbuild..."
  cd node_modules/esbuild && npm run postinstall || true && cd ../..
fi

# protobufjs needs code generation
if [ -d "node_modules/protobufjs" ]; then
  echo "[Vercel Build] Preparing protobufjs..."
  cd node_modules/protobufjs && npm run build || true && cd ../..
fi

# node-llama-cpp is skipped intentionally (requires cmake)
echo "[Vercel Build] Skipping node-llama-cpp (not available in serverless)"

# Build the application
echo "[Vercel Build] Building application..."
pnpm build

echo "[Vercel Build] Build completed successfully!"
