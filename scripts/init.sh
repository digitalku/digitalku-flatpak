#!/bin/sh
# Creates the empty OSTree repository at public/repo. Run once, ever: the
# repository is appended to from then on, and making a second one would give
# every installed application a history that does not continue.
set -eu
. "$(dirname "$0")/lib.sh"

[ ! -e "$REPO" ] || die "$REPO already exists"
mkdir -p "$PUBLIC"
ostree_cmd init --repo="$REPO" --mode=archive-z2
# A summary, even an empty one, is what makes the remote addable before the
# first application is published.
require_key
# shellcheck disable=SC2086
flatpak build-update-repo $gpg_args --title="$REMOTE_TITLE" \
  --comment="$REMOTE_COMMENT" --description="$REMOTE_DESCRIPTION" \
  --homepage="$REMOTE_HOMEPAGE" --icon="$REMOTE_ICON" \
  --default-branch="$BRANCH" "$REPO"
printf 'Created %s\n' "$REPO"
