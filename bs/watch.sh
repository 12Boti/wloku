set -eu
find src | entr -ccd bash bs/build.sh
