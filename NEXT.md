# Where this stands

Last worked on 2026-11-07. Read this, then README.md. A release follows
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
  on `flatpak.digitalku.com`, the `digitalku-r2` profile (renamed
  `digitalku-flatpak-r2` on 2026-11-07), `site/` uploaded,
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

- **The third release**, 2026-11-07: Roost 0.2.2 (`v0.2.2`, pushed), a fix
  for the grid's scroll after a preview, published as stable
  `c7b8799b92f35a97ad74e2eac1ef807f138dc0ac515be298aefdcb05baf42f57` (app
  commit `c98380af…`) with 87 files uploaded. A fresh installation reads 0.2.2
  from the live remote once its appstream is fetched; this machine's system
  `remote-info` said 0.2.1 beside the new commit until then, which is the
  appstream cache and not the remote. The delta from 0.2.1 is **155,445
  bytes** (`deltas/q5/…-x7/…`): the renderer bundle and eleven version numbers.

- **The fourth release**, 2026-11-08: Roost 0.2.3 (`v0.2.3`, pushed), which
  gives the sandbox `--socket=pulseaudio`: every earlier release played video
  without sound, its audio service crashing in `libpulse` by way of ALSA.
  Published as stable
  `f262ee200ea69fb5df57acc80943f1fd98a2597ff8b85469a08740333b9b8cf3` (app
  commit `1605d3dc…`). A fresh installation reads 0.2.3 from the live remote,
  with `pulseaudio` in its sockets. The delta from 0.2.2 is **14,313 bytes**
  (`deltas/x7/…-8m/…`): the metadata and eleven version numbers.

- **The fifth release**, 2026-11-17: Roost 0.2.4 (`v0.2.4`, pushed): a view
  for each kind of place, and a dark title bar (`GTK_THEME=Adwaita:dark` in
  the launcher, because the sandbox lacks the desktop's theme). The first
  release from Ubuntu 26.04: `org.flatpak.Builder`, the 26.08 SDK, its node22
  extension and the Electron BaseApp were installed again, the signing subkey
  imported from `~/Documents/Keys/digitalku-gnupg.tar`, and `awscli` from
  apt. Published as stable
  `2af2678af9be16a858cce350b64b74670171c66ebcbbe4845f3586d39c26fd7d` (app
  commit `68b49311…`), 150 files uploaded. A fresh installation reads 0.2.4
  from the live remote once its appstream is fetched. The delta from 0.2.3 is
  **231,509 bytes** (`deltas/8m/…-Kv/…`), larger than the last because
  libvips was built anew rather than taken from the state cache.

- **The sixth release**, 2026-11-22: Roost 0.2.5 (`v0.2.5`, pushed):
  `Delete` inside a folder keeps a file that is in another folder too, a
  folder's delete spares such files, and a *No folder* place. Built with the
  state cache, tried in an isolated installation (0.2.5, no network, the CLI
  inside the sandbox imported and drew three PNGs), and published as stable
  `90f10f52b61c78048b5376c60f0a1c6d0d743e2d66091e69d245eb1efc6060ff` (app
  commit `28961a24…`). A fresh installation installed 0.2.5 from the live
  remote. The delta from 0.2.4 is **262,893 bytes** (`deltas/Kv/…-kP/…`).

- **The seventh release**, 2026-11-23: Roost 0.2.6 (`v0.2.6`, pushed): dragging
  files out works on GNOME (Electron's file-transfer portal switched on), a closed
  Roost no longer leaves its library locked (main waits for the engine, and the
  lock records its process's start time), and only the latest staged copies are
  kept. Tried in an isolated installation (0.2.6, same permissions), published as
  stable `1b1a080f18338b854b6db43c22ee14b6343b9913ef8d8be36bd56bf81f87e013` (app
  commit `81b2c324…`), 109 files in the dry run. A fresh installation installed
  0.2.6 from the live remote. The delta from 0.2.5 is **36,809 bytes**.

- **The eighth release**, 2026-11-23: Roost 0.2.7 (`v0.2.7`, pushed): a lock
  an older build left, holding a pid alone, is taken over when the live process
  behind that pid started after the file was written. 0.2.6 still refused the
  owner's library over such a file. Tried in an isolated installation, published
  as stable `0613603ce99496310b35134d2c3ff1605aa0c9b598300674d67b75d70d1c6c71` (app commit `7b80af9b…`), 88 files in the dry run. A fresh
  installation installed 0.2.7 from the live remote. The delta from 0.2.6 is
  **17,493 bytes**.

- **The ninth release**, 2026-11-23: Roost 0.2.8 (`v0.2.8`, pushed): Markdown
  and plain text shown and edited in the window (CodeMirror 6, saved on leaving),
  a thumbnail of a text file's first lines in a bundled Noto Sans Mono, and Add's
  New file, import and paste landing in the folder on screen. The first release
  with new npm packages since the remote began: 32 entries were added to Roost's
  `generated-sources.json` from its lockfile by hand, `flatpak-node-generator`
  not being installed on Ubuntu, and the offline build took them. Tried in an
  isolated installation (the sandboxed CLI drew a `.md` and a `.txt`), published
  as stable `0c13ad003d64705e6049eeaf1c0788da8276208d361f9f1530aa2af95902ed57`
  (app commit `77b26a43…`), 798 files in the dry run. A fresh installation
  installed 0.2.8 from the live remote. The delta from 0.2.7 is
  **1,201,203 bytes**: the renderer bundle, CodeMirror in it.

- **The tenth release**, 2026-11-25: Roost 0.2.9 (`v0.2.9`, pushed): a file
  saved by another application shows its new contents in the preview and the
  inspector without a restart, its `roost://file/` address now carrying the
  content hash. No new packages. Tried in an isolated installation (0.2.9, the
  new address in the renderer bundle), published as stable
  `a9016bee938201aeb4666df495a29172599345c00c1654e7b4e5d4c1530e1276`
  (app commit `d85b9b6e…`), 101 files in the dry run, nothing deleted. A fresh
  installation reads 0.2.9 from the live remote. The delta from 0.2.8 is
  **24,991 bytes**.

- **The eleventh release**, 2026-11-25: Roost 0.2.10 (`v0.2.10`, pushed): *Copy
  this frame* in the menu over a video open in the preview, the frame drawn from
  the `<video>` by the window and put on the clipboard as a PNG. No new packages.
  Tried in an isolated installation (0.2.10, the row in the renderer bundle),
  published as stable
  `978081699c88655b727ee1d16eaabdd03bf76c4cd11aa4ade06cb65c84fa1c79`
  (app commit `c0cd3392…`), 100 files in the dry run, nothing deleted. A fresh
  installation reads 0.2.10 from the live remote. The delta from 0.2.9 is
  **32,715 bytes**.

- **The twelfth release**, 2026-11-27: Roost 0.3.0 (`v0.3.0`, pushed): a
  password on a library, which makes it format version 3 so that 0.2 and older
  refuse it, and *Share on this network…*, which this Flatpak cannot use yet
  (no `--share=network`) and says so. No new npm packages; the new workspace
  package `@roost/server` came across with the tree. Tried in an isolated
  installation (0.3.0, the server's `dist/` present, the window up), published as
  stable `d1fdd1c3f826f841e4e5af515ac667a695a1d18cfa7801f164b551a7a746bc6f`
  (app commit `d80601a3…`), 219 objects in the dry run, nothing deleted. A fresh
  installation reads 0.3.0 from the live remote, signature verified. The delta
  from 0.2.10 is **153,891 bytes**.

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
