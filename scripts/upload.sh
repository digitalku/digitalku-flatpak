#!/bin/sh
# Uploads public/ to the R2 bucket, in the order a client can never see half
# of: what the new summary points at first, the summary last.
#
#   scripts/upload.sh [--dry-run]
#
# Nothing in the bucket is deleted. The repository is append-only, and an
# object a client already holds a reference to must stay where it was.
set -eu
. "$(dirname "$0")/lib.sh"

dry=
case ${1-} in
  --dry-run) dry=--dryrun ;;
  '') ;;
  *) die "usage: upload.sh [--dry-run]" ;;
esac

require_bucket
[ -f "$REPO/summary" ] || die "$REPO has no summary; nothing has been published"

# The tree must have been written for the address it is going to. A tree made
# for a local test carries a localhost URL and, usually, the test key.
repo_file=$PUBLIC/$REMOTE_NAME.flatpakrepo
[ -f "$repo_file" ] || die "$repo_file does not exist; run scripts/refs.sh"
grep -qxF "Url=$BASE_URL/repo/" "$repo_file" ||
  die "$repo_file does not point at $BASE_URL/repo/; run scripts/refs.sh"
embedded=$(sed -n 's/^GPGKey=//p' "$repo_file")
if [ -f "$RELEASE_KEY" ]; then
  [ "$embedded" = "$(gpg --dearmor <"$RELEASE_KEY" | base64 -w0)" ] ||
    die "$repo_file carries a key other than keys/digitalku.asc; this tree was signed for something else"
elif [ "${DKF_ALLOW_TEST_KEY-}" != 1 ]; then
  die "keys/digitalku.asc does not exist, so this tree can only be signed with a test key"
fi

dest=s3://$R2_BUCKET
immutable='public, max-age=31536000, immutable'
mutable='no-cache'

say() { printf '== %s\n' "$*"; }

# 1. Content-addressed, so never changed once written: a name is a hash.
#    `sync` sends only what the bucket lacks.
for dir in objects deltas delta-indexes summaries; do
  [ -d "$REPO/$dir" ] || continue
  say "repo/$dir"
  s3 sync $dry --only-show-errors --no-progress --cache-control "$immutable" \
    "$REPO/$dir" "$dest/repo/$dir"
done

# 2. The refs, and the repository's config. Small, and changed in place, so
#    always sent rather than compared.
say "repo/refs, repo/config"
s3 cp $dry --only-show-errors --no-progress --recursive --cache-control "$mutable" \
  "$REPO/refs" "$dest/repo/refs"
s3 cp $dry --only-show-errors --no-progress --cache-control "$mutable" \
  "$REPO/config" "$dest/repo/config"

# 3. The summary, last. Each signature goes up just before its file. Between
#    the two there is a moment where a client fetching both gets a pair that
#    does not verify; it fails that refresh and succeeds on the next, and
#    cannot be shown anything unsigned.
for f in summary.sig summary summary.idx.sig summary.idx; do
  [ -f "$REPO/$f" ] || continue
  say "repo/$f"
  s3 cp $dry --only-show-errors --no-progress --cache-control "$mutable" \
    "$REPO/$f" "$dest/repo/$f"
done

# 4. What a person clicks, typed so a browser hands it to the software centre.
for f in "$PUBLIC"/*.flatpakrepo "$PUBLIC"/*.flatpakref; do
  [ -e "$f" ] || continue
  case $f in
    *.flatpakrepo) type=application/vnd.flatpak.repo ;;
    *) type=application/vnd.flatpak.ref ;;
  esac
  say "$(basename "$f")"
  s3 cp $dry --only-show-errors --no-progress --cache-control "$mutable" \
    --content-type "$type" "$f" "$dest/$(basename "$f")"
done

# 5. The site around them: icons and a landing page, when there are any.
if [ -d "$ROOT/site" ]; then
  say "site/"
  s3 sync $dry --only-show-errors --no-progress --cache-control 'public, max-age=300' \
    "$ROOT/site" "$dest"
fi
say "done"
