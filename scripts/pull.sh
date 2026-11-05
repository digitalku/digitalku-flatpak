#!/bin/sh
# Brings public/repo down from the bucket, so a publish can build on what the
# remote actually holds. Needed on a machine that has no public/, or whose
# copy is older than the bucket's: publishing onto a stale copy makes a commit
# whose parent is not the remote's latest, and an installed copy then sees
# history go backwards.
set -eu
. "$(dirname "$0")/lib.sh"

require_bucket
mkdir -p "$REPO"
s3 sync --only-show-errors --no-progress --exclude 'tmp/*' --exclude 'state/*' \
  "s3://$R2_BUCKET/repo" "$REPO"
# A ref is always 65 bytes, so `sync` could take a moved one for unchanged.
# The files that change in place are fetched whatever the comparison says.
s3 cp --only-show-errors --no-progress --recursive "s3://$R2_BUCKET/repo/refs" "$REPO/refs"
for f in config summary summary.sig summary.idx summary.idx.sig; do
  s3 cp --only-show-errors --no-progress "s3://$R2_BUCKET/repo/$f" "$REPO/$f" 2>/dev/null ||
    [ "$f" != config ] || die "the bucket has no repo/config; is it the remote's?"
done
# A bucket holds no empty directories, and OSTree expects these to exist.
mkdir -p "$REPO/tmp" "$REPO/state" "$REPO/extensions" \
  "$REPO/refs/heads" "$REPO/refs/remotes" "$REPO/refs/mirrors"
ostree_cmd fsck --repo="$REPO" --quiet >/dev/null ||
  die "$REPO does not verify after the pull"
printf 'Pulled %s into %s\n' "s3://$R2_BUCKET/repo" "$REPO"
