# The signing key

Not made yet. The plan:

- **An Ed25519 primary key**, made and kept offline (on a USB stick, plus a
  printed or second offline copy). It certifies and does nothing else.
- **A signing subkey**, the only secret on the machine that publishes. It is
  exported with `gpg --export-secret-subkeys`, so the primary's secret is never
  there. Signing with the primary's fingerprint then uses the subkey.
- **`remote.conf`'s `GPG_KEY_ID`** is the primary's fingerprint, and
  `digitalku.asc` here is its public block (`gpg --armor --export <fpr>`). That
  public block is what goes into every `.flatpakrepo` and `.flatpakref`.

**Give the signing subkey no expiry.** Every user's machine keeps the copy of
the public key it was given when it added the remote, and Flatpak does not
fetch a newer copy by itself. An expiry, a renewed expiry, and a new subkey
all live in a key block the user does not have yet. Each of them would stop
updates until the user adds the remote again from a fresh `.flatpakrepo`.

The same applies if the subkey is lost or leaks. It is revoked from the
offline primary and replaced, and every user re-adds the remote. That is the
price of a key with no online authority behind it, and it is why the secret
lives on one machine only.
