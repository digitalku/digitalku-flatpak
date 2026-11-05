# Where this stands

Last worked on 2026-11-05, in two sessions. Read this, then README.md.

## Done

- Publishing: `init.sh`, `publish.sh`, `refs.sh`, with `remote.conf` and
  `apps/com.digitalku.roost.conf`.
- Uploading and pulling: `upload.sh` (ordered, nothing deleted, guarded
  against a test tree) and `pull.sh`.
- The whole cycle, tried locally against moto standing in for R2 (README §5):
  publish, upload, install from the bucket, pull into an empty copy, publish
  again, update.
- `site/`: the landing page and the icons, checked in a browser at desktop
  and phone width, light and dark, and served from the emulated bucket with
  the right content types (README §6).
- The key scheme, tried with throwaway keys: a keyring holding only the
  signing subkey signs, and Flatpak verifies against the public block. The
  steps for the real key are in `keys/README.md`.

Every commit published in the tests had the same tree. The update path is
proven, but the size of a delta for a real code change has not been measured.

## Next, in order

The remote's name, address and branch are confirmed, and there is no
collection id (README §2).

1. **Owner: the real GPG key** (`keys/README.md`, "Making it"). Then commit
   `keys/digitalku.asc` and `GPG_KEY_ID` in `remote.conf`.
2. **Owner: the bucket** (README §4, "Setting up the bucket"): the bucket,
   the custom domain `flatpak.digitalku.com`, the Cache Rule, an API token,
   and the `digitalku-r2` profile for the AWS CLI. Then set `R2_ENDPOINT` in
   `remote.conf`.
3. **The first real publish** (README §4, "The first real publish"), from a
   release build of Roost.
4. **Roost's side.**
   - Amend ADR-0063 §10, which still says a bundle on GitHub Releases.
   - Decide whether Roost's release build passes `--default-branch=stable`, or
     keeps building `master` and lets `publish.sh` rename it as it does now.
   - Replace the install instructions on roost.digitalku.com.

## Leftovers safe to delete

`scratch/` (test keys, the moto venv, the isolated `FLATPAK_USER_DIR`s, a
pulled copy) and `public/` (the test repository). Neither is in git.

The repository has no git remote yet.
