# Where this stands

Last worked on 2026-11-06. Read this, then README.md. A release follows
RELEASING.md.

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

- **The first real publish**, 2026-11-05: Roost 0.2.0 (`v0.2.0` in the Roost
  repository) on `app/com.digitalku.roost/x86_64/stable`, 2,948 objects and
  163 MB in the bucket, matching the local tree. An empty installation
  installed it from `https://flatpak.digitalku.com/com.digitalku.roost.flatpakref`
  in 15 s, with `gpg-verify` and `gpg-verify-summary` on. The objects carry
  `immutable` for a year and a second `GET` is a `HIT`; the summary and refs
  are `no-cache`.

- **The second release**, 2026-11-06: Roost 0.2.1 (`v0.2.1`, pushed), a fix
  for thumbnails after an import, built by `build-release.sh` and published
  as stable `ab913f0673c5c036cc7ed904c7b220c6fd1d1a833a8b3d7069f878757b109494`
  (app commit `cec372fe…`) with 93 files uploaded. `remote-info` against the
  live remote says 0.2.1. **The first delta for a real code change is 68,245
  bytes** (`deltas/3f/…-q5/…`, 0.2.0 to 0.2.1) against a 149.9 MB full
  download: the change was a few compiled files and eleven version numbers.
  What Discover shows for it is still to be noted.

The owner's own Roost moved to this remote the same day, in the system
installation.

**Signing.** The pinentry window a background process opens can time out
unseen. Before `init.sh` or `publish.sh`, prime the agent from your own
terminal, which keeps the passphrase for ten minutes:

```sh
echo test | gpg --local-user 61A0073CA3B4489283A0748371819AAD7FCB1E2F --clearsign > /dev/null && echo OK
```

## Next, in order

The remote's name, address and branch are confirmed, and there is no
collection id (README §2).

1. **Roost's side.**
   - Amend ADR-0063 §10, which still says a bundle on GitHub Releases.
   - Decide whether Roost's release build passes `--default-branch=stable`, or
     keeps building `master` and lets `publish.sh` rename it as it does now.
   - Replace the install instructions on roost.digitalku.com and in Roost's
     README.
2. **Note what Discover downloads** for the owner's update from 0.2.0 to
   0.2.1, beside the 68 KB the delta weighs in the repository.

## Leftovers safe to delete

`scratch/` (test keys, the moto venv, the isolated `FLATPAK_USER_DIR`s, a
pulled copy, upload logs). Not in git.

**`public/` is now the real repository.** It is not in git either, and it is
never rebuilt: lose it and `scripts/pull.sh` brings it back from the bucket.

The repository is at git@github.com:digitalku/digitalku-flatpak.git. Commit messages carry no AI co-author or attribution line.
