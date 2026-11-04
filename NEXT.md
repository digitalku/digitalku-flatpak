# Where this stands

Paused on 2026-11-05, after the first session. Read this, then README.md.

## Done

- The scripts in `scripts/`, `remote.conf`, and `apps/com.digitalku.roost.conf`.
- A local prototype (README §5) with a test key and a loopback server.
  Roost installed from its `.flatpakref` with signature checking on. A second
  commit was installed as an update through a static delta. A summary signed
  by another key was refused.
- The second commit's tree was identical to the first. The update path is
  proven, but the size of a delta for a real code change has not been measured.

## Next, in order

1. **The real GPG key**, made by the owner and not by a script
   (`keys/README.md`). An Ed25519 primary kept offline, and a signing subkey
   with **no expiry**: Flatpak never refreshes a public key a user already
   holds. Then put its fingerprint in `remote.conf`, its public block in
   `keys/digitalku.asc`, and run `scripts/init.sh` once against the real
   `public/`. The test repository in `public/` is thrown away first.
2. **`scripts/upload.sh` to Cloudflare R2.** Upload `objects/` and `deltas/`
   first, then `refs/`, and the `summary*` files, `summaries/` and `config`
   last. Set the cache rules: `summary*`, `summaries/`, `config` and `refs/`
   uncached; `objects/` and `deltas/` immutable. Decide between rclone and
   wrangler, and how to pull `public/` back down before publishing from
   another machine.
3. **The icons and a landing page**: `digitalku.svg`,
   `icons/com.digitalku.roost.png`, and an `index.html` linking the
   `.flatpakrepo` and each `.flatpakref`.
4. **Roost's side.**
   - Amend ADR-0063 §10, which still says a bundle on GitHub Releases.
   - Decide whether Roost's release build passes `--default-branch=stable`, or
     keeps building `master` and lets `publish.sh` rename it as it does now.
   - Replace the install instructions on roost.digitalku.com.
5. **Optional: a collection id**, needed only for USB or peer-to-peer
   installs. Cheapest before the first real user.

## Leftovers safe to delete

`scratch/` (the test key and the isolated `FLATPAK_USER_DIR`, about 500 MB)
and `public/` (the test repository, about 175 MB). Neither is in git.

The repository has no git remote yet.
