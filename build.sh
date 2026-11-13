#!/usr/bin/env bash
# Build a launcher at bin/bqn-hist (BQN runs on the JVM; no compilation needed).
# The wrapper puts the toolchain JDK on PATH and calls $TC/bqn/bqn.
set -euo pipefail
cd "$(dirname "$0")"
TC="${TC:-$HOME/.local/toolchains}"
[ -x "$TC/bqn/bqn" ] || { echo "FATAL: BQN not found at $TC/bqn/bqn (set TC)"; exit 1; }
mkdir -p bin
cat > bin/bqn-hist <<WRAP
#!/usr/bin/env bash
DIR="\$(cd "\$(dirname "\$0")/.." && pwd)"
TC="\${TC:-\$HOME/.local/toolchains}"
export PATH="\$TC/jdk/bin:\$TC/bqn:\$PATH"
exec "\$TC/bqn/bqn" "\$DIR/src/main.bqn" "\$@"
WRAP
chmod +x bin/bqn-hist
echo "built bin/bqn-hist"