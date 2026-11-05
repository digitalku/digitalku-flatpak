# The signing key

Made by the owner on 2026-11-05, by hand, with the steps below:

```
pub   ed25519 2026-11-05 [C]
      61A0073CA3B4489283A0748371819AAD7FCB1E2F
uid   Digitalku Flatpak <flatpak@digitalku.com>
sub   ed25519 2026-11-05 [S]
```

No part of it expires. `digitalku.asc` here is its public block.

| Where | Holds |
| --- | --- |
| `~/.gnupg` on the publishing machine | The signing subkey's secret alone (`sec#`, `ssb [S]`) |
| `~/Documents/Keys/digitalku-gnupg.tar` | The whole keyring: primary, subkey, revocation certificate. Covered by the owner's regular disk backups |
| The owner's password manager | The passphrase, which protects every copy of the secrets |

## The shape

- **An Ed25519 primary key** that certifies and does nothing else, kept out of
  the everyday keyring. It is **not** kept on a USB stick, and that was a
  choice. Flatpak pins the key block a user received, so a subkey minted with
  a stolen primary is one no installed copy accepts. The primary can only
  revoke or replace the subkey, which makes losing it the real risk, more than
  having it stolen, and a file in a backed-up folder is lost less easily than
  a stick in a drawer.
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

The keyring is made **in memory** (`/dev/shm`), packed into one tar, and then
wiped, so the only copies are the tar and the subkey in `~/.gnupg`.

GnuPG asks for a passphrase in a pinentry window. Choose a long one and keep it
in a password manager: without it, every copy of the key is useless.

Run all three parts in **one terminal**. Parts 2 to 6 depend on `GNUPGHOME`
and `FPR` from part 1, and a fresh terminal has neither.

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

# 5. The whole keyring, primary and revocation certificate included, into a
#    backed-up folder. Stop its agent first so nothing is half-written.
gpgconf --kill gpg-agent
mkdir -p ~/Documents/Keys
tar -C "$GNUPGHOME" -cf ~/Documents/Keys/digitalku-gnupg.tar .
chmod 600 ~/Documents/Keys/digitalku-gnupg.tar

# 6. Check, then wipe the copy in memory.
gpg --homedir ~/.gnupg --list-secret-keys "$FPR"   # must show `sec#` and `ssb ... [S]`
rm -rf "$GNUPGHOME"; unset GNUPGHOME
echo "$FPR"
```

The revocation certificate GnuPG wrote is
`openpgp-revocs.d/<FPR>.rev` inside the tar. It revokes the key without the
passphrase, so a printed copy kept elsewhere still works when the passphrase
is lost.

Then set `GPG_KEY_ID=<FPR>` in `remote.conf` and commit it together with
`keys/digitalku.asc`.

The subkey keeps the passphrase, so `publish.sh` and `init.sh` ask for it in
a pinentry window. The agent remembers it for a few minutes, which covers
one publish. Steps 1 to 6 were rehearsed on 2026-11-05 with a throwaway key:
the import gives `sec#` and `ssb [S]`, and the tar holds the primary, the
subkey and the revocation certificate.

## Using the primary later

Only to revoke the subkey or make a new one. Unpack the tar into memory,
work there, and wipe it again:

```sh
export GNUPGHOME=$(mktemp -d /dev/shm/digitalku-gnupg.XXXXXX)
tar -C "$GNUPGHOME" -xf ~/Documents/Keys/digitalku-gnupg.tar
# ...
gpgconf --kill gpg-agent; rm -rf "$GNUPGHOME"; unset GNUPGHOME
```
