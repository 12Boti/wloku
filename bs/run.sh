set -eu
bash bs/build.sh
w4 run zig-out/lib/cart.wasm
