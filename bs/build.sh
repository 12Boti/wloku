set -eu
bash bs/assets.sh
mkdir -p build
zig build --cache-dir build/zig-cache -p build --prominent-compile-errors
wasm-opt -Oz -o build/lib/cart.wasm build/lib/cart.wasm \
    --zero-filled-memory --strip-producers --converge
echo "cart is $(stat -c '%s' build/lib/cart.wasm) bytes"
