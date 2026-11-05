# The signing key

Not made yet. It is made **by the owner, by hand**, never by a script in this
repository. The scheme was tried end to end with throwaway keys on 2026-11-05:
a publishing keyring holding only the subkey (`sec#`) signed a summary, and
Flatpak verified it against the exported public block.

## The shape

- **An Ed25519 primary key** that certifies and does nothing else. Made on, and
  kept on, offline storage: a USB stick, plus a second offline copy.
- **An Ed25519 signing subkey with no expiry.** Its secret half is the only
  secret on the machine that publishes, exported with
  `--export-secret-subkeys`, so the primary's secret is never there.
- **`GPG_KEY_ID` in `remote.conf` is the primary's fingerprint.** With the
  primary's secret absent, GnuPG signs with the subkey.
- **`keys/digitalku.asc` is the public block.** It is committed, embedded in
  every `.flatpakrepo` and `.flatpakref`, and checked by `upload.sh`, which
  refuses a tree carrying any other key.

**Why no expiry.** Every user's machine keeps the copy of the public key it
was given when it added the remote, and Flatpak never fetches a newer one. An
expiry, a renewed expiry, and a new subkey all live in a key block the user
does not have yet. Any of them would stop updates until the user adds the
remote again from a fresh `.flatpakrepo`. The same is true if the subkey is
lost or leaks: it is revoked from the offline primary and replaced, and every
user re-adds the remote. That is the price of a key with no online authority
behind it, and it is why the secret lives on one machine only.

## Making it

The user id below is a suggestion. Change the address before running.

```sh
# On the offline storage. Nothing here touches ~/.gnupg.
export GNUPGHOME=/path/on/the/usb/stick/digitalku-gnupg
mkdir -m 700 "$GNUPGHOME"

gpg --quick-generate-key 'Digitalku Flatpak <flatpak@digitalku.com>' ed25519 cert never
FPR=$(gpg --list-keys --with-colons | awk -F: '$1 == "fpr" { print $10; exit }')
gpg --quick-add-key "$FPR" ed25519 sign never

# The public block, into this repository.
gpg --armor --export "$FPR" > keys/digitalku.asc

# The signing subkey's secret, to carry to the publishing machine.
gpg --armor --export-secret-subkeys "$FPR" > signing-subkey.asc
echo "$FPR"
```

GnuPG writes a revocation certificate for the primary into
`$GNUPGHOME/openpgp-revocs.d/` by itself. Keep a copy of it apart from the
key, on paper or a second stick.

On the publishing machine:

```sh
gpg --import signing-subkey.asc
gpg --list-secret-keys        # must show `sec#` (primary absent) and `ssb ... [S]`
shred -u signing-subkey.asc
```

Then set `GPG_KEY_ID=<FPR>` in `remote.conf`, commit it together with
`keys/digitalku.asc`, and follow README §4 from "the first real publish".
