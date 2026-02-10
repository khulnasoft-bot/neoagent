# Vercel Deployment Guide

Deploy OpenClaw Gateway to Vercel for cloud-based hosting with WebChat UI support.

## Prerequisites

- Vercel account (free or paid)
- Git repository with OpenClaw source code
- Node.js 22+ (Vercel runtime)
- pnpm package manager

## Quick Start

### 1. Connect Your Repository

```bash
git push origin main
```

Then connect your GitHub repository to Vercel:

1. Go to [vercel.com](https://vercel.com)
2. Click "New Project"
3. Select your OpenClaw repository
4. Authorize Vercel access

### 2. Configure Environment Variables

In your Vercel project settings, add these environment variables:

**Required:**

- `ANTHROPIC_API_KEY` or `OPENAI_API_KEY` - LLM provider credentials
- `NODE_OPTIONS` - Memory configuration (e.g., `--max-old-space-size=2048`)

**Optional:**

- `OPENCLAW_GATEWAY_TOKEN` - API token for gateway authentication
- `OPENCLAW_GATEWAY_PASSWORD` - Password for gateway authentication
- `LOG_LEVEL` - Logging level (info, debug, warn, error)

### 3. Deploy

Vercel will automatically build and deploy when you push to `main`:

```bash
git push origin main
```

Or trigger manually:

```bash
vercel deploy --prod
```

## Deployment Configuration

### Gateway Only (vercel.json)

For a minimal API gateway without WebChat UI:

```bash
vercel deploy --prod -c vercel.json
```

**Features:**

- Lightweight API gateway
- Minimal build time
- Suitable for CLI/bot integrations

### Gateway + WebChat UI (vercel-webchat.json)

For full Control UI and WebChat support:

```bash
vercel deploy --prod -c vercel-webchat.json
```

**Features:**

- Full Control UI dashboard
- WebChat interface
- Static asset caching
- WebSocket support for real-time messaging
- Larger function memory (3GB)

## Environment Configuration

### Production Settings

Create `.env.production` in your repository root:

```env
NODE_ENV=production
OPENCLAW_GATEWAY_PORT=3000
OPENCLAW_GATEWAY_BIND=0.0.0.0

# LLM Configuration
ANTHROPIC_API_KEY=sk-ant-...
# or
OPENAI_API_KEY=sk-...

# Security
OPENCLAW_GATEWAY_PASSWORD=secure-password-here

# Logging
LOG_LEVEL=info

# Optional: Model configuration
OPENCLAW_DEFAULT_MODEL=anthropic/claude-opus-4-6
```

**Security Note:** Never commit API keys to git. Use Vercel Environment Variables instead.

## Gateway Access

After deployment, access your gateway:

- **Gateway URL:** `https://<your-deployment>.vercel.app`
- **WebSocket Endpoint:** `wss://<your-deployment>.vercel.app/ws`
- **WebChat UI:** `https://<your-deployment>.vercel.app/webchat` (with WebChat config)

### With Authentication

If you set `OPENCLAW_GATEWAY_PASSWORD`:

```bash
curl -H "Authorization: Bearer YOUR_PASSWORD" \
  https://<your-deployment>.vercel.app/health
```

## Connecting Clients

### CLI Client

```bash
openclaw agent --gateway wss://<your-deployment>.vercel.app/ws \
  --token "your-gateway-password"
```

### Python SDK

```python
from openclaw import AsyncGatewayClient

async with AsyncGatewayClient(
    uri="wss://<your-deployment>.vercel.app/ws",
    token="your-gateway-password"
) as client:
    response = await client.agent_query("What time is it?")
    print(response)
```

## WebChat Deployment

WebChat UI is served directly from the gateway at `/webchat`:

```
https://<your-deployment>.vercel.app/webchat
```

**Features:**

- Browser-based interface
- Real-time streaming responses
- File attachments support
- Session management

## Scaling & Performance

### Memory Configuration

Default: 1024 MB per function

For production workloads:

```json
"functions": {
  "openclaw.mjs": {
    "memory": 3008,
    "maxDuration": 60
  }
}
```

Vercel supports up to 3008 MB per function on Pro plans.

### Build Optimization

**Reduce Build Time:**

1. Use `.vercelignore` to exclude unnecessary files
2. Minimize dependencies in package.json
3. Skip building native modules if possible

**Current Build Excludes:**

- Documentation files
- Test files
- Platform-specific apps (iOS/Android/macOS)
- Git history

## Monitoring & Debugging

### View Logs

```bash
vercel logs <your-deployment>
```

### Health Check

```bash
curl https://<your-deployment>.vercel.app/health
```

### Performance

- Vercel Analytics automatically tracks performance
- Monitor function execution time in Vercel dashboard
- Check cold start performance in Function Logs

## Advanced Configuration

### Custom Domain

1. Add domain in Vercel project settings
2. Configure DNS records as shown in Vercel
3. Enable auto-renewal for SSL certificates

### Regional Deployment

Default region: `sfo1` (San Francisco)

To change region, modify `vercel.json`:

```json
"regions": ["iad1"]  // Virginia
"regions": ["arn1"]  // Stockholm
"regions": ["sin1"]  // Singapore
```

### Concurrent Deployments

By default, only the latest deployment is active.

To enable canary deployments:

1. Go to project settings
2. Enable "Automatic Git integrations"
3. Configure preview deployments

## Troubleshooting

### npm Install Fails with node-llama-cpp Error

**Error Message:** `cmake not found` or `node-llama-cpp failed to build`

```
[node-llama-cpp] Failed to build llama.cpp with no GPU support. Error: cmake not found
npm error code 1
npm error path /vercel/.../node_modules/node-llama-cpp
```

**Root Cause:** `node-llama-cpp` is an optional peer dependency with a postinstall script that tries to build native binaries. Vercel's serverless environment doesn't include build tools like cmake.

**Solution:** This is already fixed in the latest version:

1. `.npmrc` configured with `ignore-scripts=true` to skip postinstall scripts during install
2. `node-llama-cpp` marked as optional in `package.json`
3. Custom Vercel build script (`scripts/vercel-build.sh`) selectively runs only essential postinstall scripts
4. node-llama-cpp is intentionally skipped during build

**Build Process:**

- Vercel uses `bash scripts/vercel-build.sh` which:
  - Installs dependencies with `--ignore-scripts` flag
  - Runs postinstall for essential packages only (sharp, esbuild, protobufjs)
  - Skips node-llama-cpp entirely
  - Builds the application

**If you need local embeddings:**

- Use cloud embedding providers (OpenAI, Anthropic, Cohere)
- Deploy locally or on dedicated infrastructure that supports native builds
- Use Docker deployment (Dockerfile has necessary build tools)

### Build Fails

**Issue:** `tsdown` not found

- **Solution:** Ensure all dependencies are installed: `pnpm install --frozen-lockfile`

**Issue:** Memory exceeded during build

- **Solution:** Use `--filter` to skip non-essential packages:
  ```bash
  pnpm install --frozen-lockfile --filter openclaw
  ```

### Gateway Won't Start

**Issue:** `EACCES: permission denied`

- **Solution:** Check file permissions. Vercel runs as `node` user.

**Issue:** Port already in use

- **Solution:** Vercel automatically assigns ports. Ensure no hardcoded ports in config.

### WebSocket Connection Fails

**Issue:** `WebSocket upgrade failed`

- **Cause:** Gateway not properly configured
- **Solution:** Ensure `OPENCLAW_GATEWAY_BIND=0.0.0.0` is set

### High Latency

**Issue:** Response times > 5 seconds

- **Cause:** Cold starts or insufficient memory
- **Solution:**
  - Increase function memory to 3008 MB
  - Use deployment without WebChat UI for faster cold starts
  - Enable persistent connections to reduce handshakes

## Cost Estimation

| Deployment                   | Tier | Estimated Cost |
| ---------------------------- | ---- | -------------- |
| Gateway only                 | Free | $0/month       |
| Gateway + WebChat            | Pro  | $20-50/month   |
| High-traffic (>1000 req/day) | Pro  | $50-150/month  |

**Note:** Costs depend on:

- Request volume (Serverless Functions pricing)
- Data transfer
- Build minutes
- Additional resources (storage, domains)

## Next Steps

- [Gateway Configuration](../gateway/configuration.md)
- [Security Best Practices](../gateway/security.md)
- [WebChat Customization](../web/webchat.md)

## Support

For deployment issues:

1. Check Vercel logs: `vercel logs -f`
2. Review [Vercel troubleshooting guide](https://vercel.com/docs/deployments/troubleshoot)
3. Open issue on [OpenClaw GitHub](https://github.com/openclaw/openclaw/issues)
4. Ask in [OpenClaw Discord](https://discord.gg/clawd)
