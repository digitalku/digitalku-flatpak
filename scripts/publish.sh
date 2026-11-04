#!/bin/sh
# Publishes one build of an application onto the remote.
#
#   scripts/publish.sh [--with-debug] [--force] [--subject TEXT] APP_ID SRC_REPO [SRC_BRANCH]
#
# SRC_REPO is the repository `flatpak-builder --repo=` wrote, and SRC_BRANCH
# the branch it built (master unless the manifest or --default-branch said
# otherwise). The build is committed again on top of what the remote already
# holds, as BRANCH from remote.conf, so an installed copy sees an update with
# a delta rather than an unrelated tree. Nothing is copied from SRC_REPO but
# the one ref, and the Debug extension only when asked for.
set -eu
. "$(dirname "$0")/lib.sh"

with_debug=
force=
subject=
while [ $# -gt 0 ]; do
  case $1 in
    --with-debug) with_debug=1; shift ;;
    # Commits even when the tree is what the remote already holds: to re-sign
    # or correct a subject, never as part of an ordinary release.
    --force) force=--force; shift ;;
    --subject) subject=$2; shift 2 ;;
    -*) die "unknown option $1" ;;
    *) break ;;
  esac
done
[ $# -ge 2 ] || die "usage: publish.sh [--with-debug] [--force] [--subject TEXT] APP_ID SRC_REPO [SRC_BRANCH]"

app=$1
src=$2
src_branch=${3:-master}
arch=${DKF_ARCH:-$(flatpak --default-arch)}

[ -f "$ROOT/apps/$app.conf" ] || die "apps/$app.conf does not exist; an application is listed before it is published"
[ -d "$REPO" ] || die "$REPO does not exist; run scripts/init.sh once"
require_key

src_ref=app/$app/$arch/$src_branch
src_commit=$(ostree_cmd rev-parse --repo="$src" "$src_ref" 2>/dev/null) ||
  die "$src has no $src_ref"
[ -n "$subject" ] || subject="Publish $app from ${src_commit%"${src_commit#????????????}"}"

# shellcheck disable=SC2086
flatpak build-commit-from --src-repo="$src" --src-ref="$src_ref" \
  --subject="$subject" --no-update-summary $force $gpg_args \
  "$REPO" "app/$app/$arch/$BRANCH"

if [ -n "$with_debug" ]; then
  # shellcheck disable=SC2086
  flatpak build-commit-from --src-repo="$src" \
    --src-ref="runtime/$app.Debug/$arch/$src_branch" \
    --subject="$subject" --no-update-summary $force $gpg_args \
    "$REPO" "runtime/$app.Debug/$arch/$BRANCH"
fi

# The summary, the appstream branch Discover and GNOME Software read, and a
# static delta from the previous commit, which is what keeps an update small.
# shellcheck disable=SC2086
flatpak build-update-repo $gpg_args --generate-static-deltas \
  --static-delta-ignore-ref='*.Debug' "$REPO"

"$ROOT/scripts/refs.sh"
printf 'Published %s as app/%s/%s/%s\n' "$src_commit" "$app" "$arch" "$BRANCH"
