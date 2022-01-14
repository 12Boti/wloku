set -eu
bash bs/assets.sh
mkdir -p build
zig build --cache-dir build/zig-cache -p build
