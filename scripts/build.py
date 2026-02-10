#!/usr/bin/env python3
import subprocess
import sys
import os

os.chdir('/vercel/share/v0-project')

# Run the build command
build_cmd = [
    'pnpm',
    'build'
]

print("[v0] Starting TypeScript build process...")
print(f"[v0] Running: {' '.join(build_cmd)}")

try:
    result = subprocess.run(build_cmd, capture_output=True, text=True)
    print(result.stdout)
    if result.stderr:
        print("STDERR:", result.stderr, file=sys.stderr)
    
    if result.returncode != 0:
        print(f"[v0] Build failed with return code: {result.returncode}")
        sys.exit(result.returncode)
    
    print("[v0] Build completed successfully!")
    
except Exception as e:
    print(f"[v0] Error running build: {e}", file=sys.stderr)
    sys.exit(1)
