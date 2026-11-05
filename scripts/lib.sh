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
R2_BUCKET=${DKF_R2_BUCKET:-$R2_BUCKET}
R2_ENDPOINT=${DKF_R2_ENDPOINT:-$R2_ENDPOINT}
# Without the colon: an empty DKF_AWS_PROFILE means no profile at all, and the
# AWS CLI's own environment variables are used instead.
AWS_PROFILE_NAME=${DKF_AWS_PROFILE-$AWS_PROFILE_NAME}

# The public half of the signing key, in the repository once it exists. The
# key embedded in the .flatpakrepo and .flatpakref files is read from it.
RELEASE_KEY=$ROOT/keys/digitalku.asc
PUBLIC_KEY=${DKF_PUBLIC_KEY:-$RELEASE_KEY}

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

require_bucket() {
  [ -n "$R2_BUCKET" ] || die "no bucket: set R2_BUCKET in remote.conf or DKF_R2_BUCKET"
  [ -n "$R2_ENDPOINT" ] || die "no endpoint: set R2_ENDPOINT in remote.conf or DKF_R2_ENDPOINT"
  command -v aws >/dev/null 2>&1 || die "the AWS CLI (aws) is not installed"
}

# The S3 API of R2 through the AWS CLI. R2 has one region, `auto`.
s3() {
  if [ -n "$AWS_PROFILE_NAME" ]; then
    aws --profile "$AWS_PROFILE_NAME" --endpoint-url "$R2_ENDPOINT" --region auto s3 "$@"
  else
    aws --endpoint-url "$R2_ENDPOINT" --region auto s3 "$@"
  fi
}

# The key as a .flatpakrepo carries it: the binary key block, base64. From
# PUBLIC_KEY when it exists, so the publishing machine needs no more than the
# secret subkey; from the keyring otherwise.
embedded_key() {
  if [ -f "$PUBLIC_KEY" ]; then
    gpg --dearmor <"$PUBLIC_KEY" | base64 -w0
  else
    gpg_cmd --export "$GPG_KEY_ID" | base64 -w0
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
