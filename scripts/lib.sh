# Shared by every script in this directory. Sourced, never run.

ROOT=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck source=../remote.conf
. "$ROOT/remote.conf"

# An environment variable with the DKF_ prefix wins over remote.conf, so a
# test run can point the same scripts at a local server and a throwaway key.
REMOTE_NAME=${DKF_REMOTE_NAME:-$REMOTE_NAME}
BASE_URL=${DKF_BASE_URL:-$BASE_URL}
BASE_URL=${BASE_URL%/}
BRANCH=${DKF_BRANCH:-$BRANCH}
GPG_KEY_ID=${DKF_GPG_KEY_ID:-$GPG_KEY_ID}
GPG_HOMEDIR=${DKF_GPG_HOMEDIR:-$GPG_HOMEDIR}

PUBLIC=${DKF_PUBLIC:-$ROOT/public}
REPO=$PUBLIC/repo

die() {
  printf '%s: %s\n' "$(basename "$0")" "$*" >&2
  exit 1
}

# An unsigned remote cannot be added without --no-gpg-verify, and a user who
# learns that habit here keeps it everywhere. Nothing is published unsigned.
require_key() {
  [ -n "$GPG_KEY_ID" ] || die "no signing key: set GPG_KEY_ID in remote.conf or DKF_GPG_KEY_ID"
  gpg_args=--gpg-sign=$GPG_KEY_ID
  if [ -n "$GPG_HOMEDIR" ]; then
    gpg_args="$gpg_args --gpg-homedir=$GPG_HOMEDIR"
  fi
}

gpg_cmd() {
  if [ -n "$GPG_HOMEDIR" ]; then
    gpg --homedir "$GPG_HOMEDIR" "$@"
  else
    gpg "$@"
  fi
}

# The system's ostree if there is one, otherwise the copy inside the
# org.flatpak.Builder Flatpak, which Roost's build needs installed anyway.
ostree_cmd() {
  if command -v ostree >/dev/null 2>&1; then
    ostree "$@"
  else
    flatpak run --command=ostree org.flatpak.Builder "$@"
  fi
}
