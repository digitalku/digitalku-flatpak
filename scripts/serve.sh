#!/bin/sh
# Serves public/ on http://127.0.0.1:${DKF_PORT:-8080} for a local test. Bound
# to loopback only; the real remote is the bucket.
set -eu
. "$(dirname "$0")/lib.sh"

[ -d "$PUBLIC" ] || die "$PUBLIC does not exist"
exec python3 -m http.server --bind 127.0.0.1 --directory "$PUBLIC" "${DKF_PORT:-8080}"
