#!/bin/sh
# Makes a throwaway signing key in scratch/gnupg for a local prototype run, and
# prints the variables that point the other scripts at it. Never the real key:
# that one is made by hand, kept offline, and described in keys/README.md.
set -eu
. "$(dirname "$0")/lib.sh"

home=$ROOT/scratch/gnupg
if [ ! -d "$home" ]; then
  mkdir -p "$home"
  chmod 700 "$home"
  gpg --homedir "$home" --batch --pinentry-mode loopback --passphrase '' \
    --quick-generate-key 'Digitalku Flatpak TEST KEY <test@invalid>' ed25519 sign never >/dev/null 2>&1
fi
id=$(gpg --homedir "$home" --list-keys --with-colons 2>/dev/null | awk -F: '$1 == "fpr" { print $10; exit }')
printf 'export DKF_GPG_HOMEDIR=%s\nexport DKF_GPG_KEY_ID=%s\n' "$home" "$id"
