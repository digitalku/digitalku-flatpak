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

The keyring is made **in memory** (`/dev/shm`), copied to the USB sticks, and
then wiped, so the primary's secret never touches the internal disk. A
keyring kept directly on a FAT or exFAT stick also works badly: GnuPG wants
Unix permissions there, and that filesystem has none.

GnuPG asks for a passphrase in a pinentry window. Choose a long one, and keep
a written copy with the sticks: without it, the primary on them is useless.

```sh
# 1. A keyring in memory.
export GNUPGHOME=$(mktemp -d /dev/shm/digitalku-gnupg.XXXXXX)

# 2. The primary, which only certifies, then the signing subkey. No expiry.
gpg --quick-generate-key 'Digitalku Flatpak <flatpak@digitalku.com>' ed25519 cert never
FPR=$(gpg --list-keys --with-colons | awk -F: '$1 == "fpr" { print $10; exit }')
gpg --quick-add-key "$FPR" ed25519 sign never

# 3. The public block, into this repository.
gpg --armor --export "$FPR" > ~/Documents/Projects/software/digitalku-flatpak/keys/digitalku.asc

# 4. The signing subkey alone, into the everyday keyring of the publishing machine.
gpg --armor --export-secret-subkeys "$FPR" | gpg --homedir ~/.gnupg --import

# 5. The whole keyring, primary and revocation certificate included, onto each
#    stick. Stop its agent first so nothing is half-written.
gpgconf --kill gpg-agent
tar -C "$GNUPGHOME" -cf /run/media/$USER/<STICK>/digitalku-gnupg.tar .
#    (again for the second stick)

# 6. Check, then wipe the copy in memory.
gpg --homedir ~/.gnupg --list-secret-keys "$FPR"   # must show `sec#` and `ssb ... [S]`
rm -rf "$GNUPGHOME"; unset GNUPGHOME
echo "$FPR"
```

The revocation certificate GnuPG wrote is
`openpgp-revocs.d/<FPR>.rev` inside the tar. A printed copy, kept apart from
the sticks, means a lost passphrase can still revoke the key.

Then set `GPG_KEY_ID=<FPR>` in `remote.conf` and commit it together with
`keys/digitalku.asc`.

The subkey keeps the passphrase, so `publish.sh` and `init.sh` ask for it in
a pinentry window. The agent remembers it for a few minutes, which covers
one publish. Steps 1 to 6 were rehearsed on 2026-11-05 with a throwaway key:
the import gives `sec#` and `ssb [S]`, and the tar holds the primary, the
subkey and the revocation certificate.

## Using the primary later

Only to revoke the subkey or make a new one. Unpack a stick's tar into memory,
work there, and wipe it again:

```sh
export GNUPGHOME=$(mktemp -d /dev/shm/digitalku-gnupg.XXXXXX)
tar -C "$GNUPGHOME" -xf /run/media/$USER/<STICK>/digitalku-gnupg.tar
# ...
gpgconf --kill gpg-agent; rm -rf "$GNUPGHOME"; unset GNUPGHOME
```
