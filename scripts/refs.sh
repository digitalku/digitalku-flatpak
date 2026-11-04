#!/bin/sh
# Writes the files a person clicks to install: public/<remote>.flatpakrepo for
# the remote, and public/<app>.flatpakref for every application in apps/.
# Each carries the public key, so adding the remote verifies from the first
# pull. Run by publish.sh; run it alone after editing remote.conf or apps/.
set -eu
. "$(dirname "$0")/lib.sh"

require_key
key=$(gpg_cmd --export "$GPG_KEY_ID" | base64 -w0)
[ -n "$key" ] || die "gpg exported nothing for $GPG_KEY_ID"
mkdir -p "$PUBLIC"

cat >"$PUBLIC/$REMOTE_NAME.flatpakrepo" <<EOF
[Flatpak Repo]
Title=$REMOTE_TITLE
Url=$BASE_URL/repo/
Homepage=$REMOTE_HOMEPAGE
Comment=$REMOTE_COMMENT
Description=$REMOTE_DESCRIPTION
Icon=$REMOTE_ICON
GPGKey=$key
EOF

for conf in "$ROOT"/apps/*.conf; do
  [ -e "$conf" ] || continue
  app=$(basename "$conf" .conf)
  (
    . "$conf"
    cat >"$PUBLIC/$app.flatpakref" <<EOF
[Flatpak Ref]
Name=$app
Branch=$BRANCH
Title=$APP_TITLE
Url=$BASE_URL/repo/
SuggestRemoteName=$REMOTE_NAME
RuntimeRepo=$RUNTIME_REPO
IsRuntime=false
Homepage=$APP_HOMEPAGE
Comment=$APP_COMMENT
Description=$APP_DESCRIPTION
Icon=$APP_ICON
GPGKey=$key
EOF
  )
done
printf 'Wrote the .flatpakrepo and .flatpakref files in %s\n' "$PUBLIC"
