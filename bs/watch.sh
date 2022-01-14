set -eu
find src assets | entr -ccd bash bs/build.sh
