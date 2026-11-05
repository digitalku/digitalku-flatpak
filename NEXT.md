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
- The real signing key, made 2026-11-05: `61A0073CA3B4489283A0748371819AAD7FCB1E2F`
  (`keys/README.md`). It signed a test repository from `~/.gnupg`, holding the
  subkey alone, and Flatpak installed Roost from it after verifying against
  `keys/digitalku.asc`, with nothing else trusted.
- Cloudflare, done by the owner on 2026-11-05: the bucket `digitalku-flatpak`
  on `flatpak.digitalku.com`, the `digitalku-r2` profile, `site/` uploaded,
  the Cache Rule *Flatpak respect origin* (a second `GET` is a `HIT`, the
  site carries `max-age=300`) and the URL Rewrite *flatpak index*
  (`/` answers 200).

Every commit published in the tests had the same tree. The update path is
proven, but the size of a delta for a real code change has not been measured.

## Next, in order

The remote's name, address and branch are confirmed, and there is no
collection id (README §2).

1. **The first real publish** (README §4, "The first real publish"), from a
   release build of Roost.
2. **Roost's side.**
   - Amend ADR-0063 §10, which still says a bundle on GitHub Releases.
   - Decide whether Roost's release build passes `--default-branch=stable`, or
     keeps building `master` and lets `publish.sh` rename it as it does now.
   - Replace the install instructions on roost.digitalku.com.

## Leftovers safe to delete

`scratch/` (test keys, the moto venv, the isolated `FLATPAK_USER_DIR`s, a
pulled copy) and `public/` (the test repository). Neither is in git.

The repository is at git@github.com:digitalku/digitalku-flatpak.git. Commit messages carry no AI co-author or attribution line.
