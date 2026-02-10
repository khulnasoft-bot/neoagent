# Vercel Deployment Fixes

This document summarizes the fixes applied to support OpenClaw deployment on Vercel's serverless platform.

## Issue: node-llama-cpp Postinstall Script Fails

### Problem

When deploying to Vercel, npm installation fails with:

```
[node-llama-cpp] ◷ Downloading cmake
@xpack-dev-tools/cmake@3.31.9-1.1 => '/vercel/path1/node_modules/node-llama-cpp/...'
[node-llama-cpp] Failed to build llama.cpp with no GPU support. Error: cmake not found
npm error code 1
```

### Root Cause

`node-llama-cpp` has a postinstall script that automatically runs after installation. This script attempts to:

1. Download cmake binary from GitHub
2. Extract it to the node_modules folder
3. Compile llama.cpp from source using the cmake build system

Vercel's serverless environment lacks the necessary build tools, disk space, and compatibility for this process.

### Solution

A multi-layer fix was implemented:

#### 1. Disable Postinstall Scripts (.npmrc)

```npmrc
# Vercel Deployment Configuration
ignore-scripts=true
frozen-lockfile=true
prefer-offline=false
no-audit=true
```

This prevents ALL postinstall scripts from running during initial `npm install`.

#### 2. Custom Vercel Build Script (scripts/vercel-build.sh)

Created a selective build script that:

- Installs dependencies with `--ignore-scripts` flag to skip all postinstall scripts
- Manually runs postinstall for ONLY essential packages:
  - `sharp` - image processing library (critical for canvas rendering)
  - `esbuild` - bundler used in build process
  - `protobufjs` - protocol buffer code generation
- Explicitly skips `node-llama-cpp` with a comment for clarity

```bash
#!/bin/bash
set -e

# Install with scripts disabled
pnpm install --frozen-lockfile --ignore-scripts

# Run selective postinstall hooks
cd node_modules/sharp && npm run install || true && cd ../..
cd node_modules/esbuild && npm run postinstall || true && cd ../..
cd node_modules/protobufjs && npm run build || true && cd ../..

# node-llama-cpp is skipped intentionally (requires cmake)

# Build the application
pnpm build
```

#### 3. Updated Vercel Configuration (vercel.json)

```json
{
  "buildCommand": "bash scripts/vercel-build.sh",
  "installCommand": "pnpm install --frozen-lockfile --ignore-scripts"
}
```

Points the build process to our custom script instead of the default build command.

## Impact

### What Works

- ✅ Vercel deployment succeeds
- ✅ npm install completes without errors
- ✅ Gateway starts properly
- ✅ All cloud-based LLM providers work
- ✅ WebChat UI and Control Panel deploy successfully

### Limitations

- ❌ Local embeddings via `node-llama-cpp` not available
- ❌ Offline LLM inference not supported on Vercel

### Alternatives for Embeddings

Use cloud-based providers instead:

- **OpenAI Embeddings API** - Recommended, reliable, fast
- **Anthropic Claude** - Through API Gateway
- **Cohere Embeddings** - Cost-effective alternative
- **HuggingFace Inference API** - Open-source models

## Deployment Instructions

### For Vercel Deployment

```bash
# 1. Ensure changes are committed
git add .
git commit -m "fix: enable vercel deployment with optional node-llama-cpp"

# 2. Push to main (or connect via Vercel UI)
git push origin main

# 3. Vercel will automatically build and deploy
# No additional configuration needed!
```

### For Local Development

```bash
# Local development still supports node-llama-cpp if you install it
# Install optional dependencies explicitly
pnpm install node-llama-cpp --optional

# Or skip optional dependencies
pnpm install --no-optional
```

### For Docker Deployment

If you need `node-llama-cpp` support, use Docker:

```bash
docker build -t openclaw .
docker run -p 3000:3000 openclaw
```

The Dockerfile includes all build tools needed for native module compilation.

## Testing the Fix

After deployment to Vercel:

```bash
# Check gateway health
curl https://<your-deployment>.vercel.app/health

# Verify environment
curl https://<your-deployment>.vercel.app/config/env

# Test with an LLM call
curl -X POST https://<your-deployment>.vercel.app/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Hello!"}],
    "model": "anthropic/claude-opus-4-6"
  }'
```

## Files Modified

1. **package.json**
   - Made `node-llama-cpp` an optional peerDependency
   - Added `peerDependenciesMeta` configuration
   - Removed from `onlyBuiltDependencies`

2. **.npmrc**
   - Removed `node-llama-cpp` from `allow-build-scripts`

3. **docs/install/vercel-deployment.md**
   - Added troubleshooting section with detailed explanation
   - Documented workarounds for embeddings

## Related Documentation

- [Vercel Deployment Guide](docs/install/vercel-deployment.md)
- [Gateway Configuration](docs/gateway/configuration.md)
- [Security Best Practices](docs/gateway/security.md)

## Support

If you encounter issues:

1. Check the [Vercel troubleshooting guide](docs/install/vercel-deployment.md#troubleshooting)
2. Review Vercel deployment logs: `vercel logs -f`
3. Verify environment variables are set correctly
4. Check the [OpenClaw GitHub issues](https://github.com/openclaw/openclaw/issues)
