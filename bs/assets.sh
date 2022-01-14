set -eu
mkdir -p build/assets
find assets -name '*.png' | xargs -i env f={} sh -c \
    'png-decoder $f build/assets/$(basename ${f%.png})'
