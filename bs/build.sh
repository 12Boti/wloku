set -eu
bash bs/assets.sh
mkdir -p build
zig build --cache-dir build/zig-cache -p build
wasm-opt -Oz -o build/lib/cart.wasm build/lib/cart.wasm
echo "cart is $(stat -c '%s' build/lib/cart.wasm) bytes"
