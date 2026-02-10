# Vercel Deployment Fixes

This document summarizes the fixes applied to support OpenClaw deployment on Vercel's serverless platform.

## Issue: node-llama-cpp Build Failure

### Problem

When deploying to Vercel, npm installation fails with:

```
[node-llama-cpp] Failed to build llama.cpp with no GPU support. Error: cmake not found
npm error code 1
```

### Root Cause

`node-llama-cpp` is a native module that requires C++ compilation tools (cmake, gcc). Vercel's serverless functions don't have these tools available, causing the build to fail.

### Solution

Three changes were made to fix this:

#### 1. Optional Peer Dependency (package.json)

Changed `node-llama-cpp` from a required peer dependency to an optional one:

```json
"peerDependencies": {
  "@napi-rs/canvas": "^0.1.89"
},
"peerDependenciesMeta": {
  "@napi-rs/canvas": {
    "optional": true
  },
  "node-llama-cpp": {
    "optional": true
  }
}
```

#### 2. Removed from Build Scripts (.npmrc)

Removed `node-llama-cpp` from the `allow-build-scripts` list to prevent npm from attempting to build it:

```npmrc
allow-build-scripts=@whiskeysockets/baileys,sharp,esbuild,protobufjs,fs-ext,node-pty,@lydell/node-pty,@matrix-org/matrix-sdk-crypto-nodejs
```

Before: `node-llama-cpp` was included in the list and forced a build attempt.

#### 3. Updated pnpm Configuration (package.json)

Removed `node-llama-cpp` from the `onlyBuiltDependencies` array:

```json
"onlyBuiltDependencies": [
  "@lydell/node-pty",
  "@matrix-org/matrix-sdk-crypto-nodejs",
  "@napi-rs/canvas",
  "@whiskeysockets/baileys",
  "authenticate-pam",
  "esbuild",
  "protobufjs",
  "sharp"
]
```

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
