# Releasing

How a new version of an application reaches `https://flatpak.digitalku.com`,
from the version number to the update a user sees in Discover or GNOME
Software. Written so that the owner, or an assistant the owner asks, can follow
it start to finish without anything else open. README.md explains *why* each
script works the way it does; this file is only the order.

The example is Roost going to 0.3.0. Its source is `../roost`, next to this
repository.

## Before anything

- **The owner types the passphrase.** Nobody else ever handles it, and no
  script asks for it on its own terms (step 3).
- **`public/` is the remote's master copy.** It is appended to and never
  rebuilt. If it is missing, or older than the bucket, run `scripts/pull.sh`
  first. Never delete it, and never run `scripts/init.sh` again: that would
  give every installed copy an unrelated history.
- Every commit, in this repository and in Roost, ends at its body: no
  `Co-Authored-By` and no other line naming an assistant.

## 1. The version, in the application's repository

In `../roost`:

1. Raise `"version"` in all eleven `package.json` files: the root,
   `apps/desktop/*`, `packages/*`. About reads the root's.
2. Add a `<release version="0.3.0" date="YYYY-MM-DD">` at the **top** of
   `<releases>` in `packaging/flatpak/com.digitalku.roost.metainfo.xml`, with a
   `<description>` in plain language: what a user of 0.2.0 will notice.
   Discover and GNOME Software show it beside the update. Check it:

   ```sh
   flatpak run --command=appstreamcli org.flatpak.Builder validate --no-net packaging/flatpak/com.digitalku.roost.metainfo.xml
   ```
3. `pnpm verify` must pass.
4. Commit and tag:

   ```sh
   git commit -am "Release 0.3.0"
   git tag -a v0.3.0 -m "Roost 0.3.0"
   ```

## 2. The build

Still in `../roost`:

```sh
packaging/flatpak/build-release.sh
```

It refuses a working tree with changes, a `HEAD` that is not the tag
`v<version>`, and a metainfo with no release of that version. It builds what
the commit holds into `scratch/flatpak/repo`, installs nothing, and prints the
`publish.sh` command for the next step. A first build takes several minutes,
and a later one is faster because `scratch/flatpak/state` keeps the modules
that did not change.

Try the build before publishing it, without touching the installed copy:

```sh
export FLATPAK_USER_DIR=$PWD/scratch/flatpak/try
flatpak --user remote-add --no-gpg-verify try scratch/flatpak/repo
flatpak --user install -y try com.digitalku.roost
flatpak run --user com.digitalku.roost   # the window, and About's version
unset FLATPAK_USER_DIR; command rm -rf scratch/flatpak/try
```

## 3. The key

The owner, **in their own terminal**:

```sh
echo test | gpg --local-user 61A0073CA3B4489283A0748371819AAD7FCB1E2F --clearsign > /dev/null && echo OK
```

The agent then holds the passphrase for ten minutes, and steps 4 and 5 sign
without asking. A pinentry window opened by a command running in the
background can time out before anyone sees it. That failure looks like
`Failure signing commit file: Pinentry: Timeout`, and the cure is this step
again.

## 4. Publish, here

In this repository:

```sh
scripts/publish.sh --subject "Roost 0.3.0" com.digitalku.roost ../roost/scratch/flatpak/repo
```

This writes into `public/` only. Nothing has left the machine yet. It ends
with `Published <commit> as app/com.digitalku.roost/x86_64/stable`.

## 5. Upload

```sh
scripts/upload.sh --dry-run
scripts/upload.sh
```

The dry run lists what would go. The real run sends the new objects and the
delta first and the signed summary last, so nobody sees the new version before
everything it needs is there. It deletes nothing. It refuses a tree signed
with any key but `keys/digitalku.asc`.

## 6. Check

```sh
flatpak remote-info digitalku com.digitalku.roost     # Version: 0.3.0
```

Then update the installed copy **through Discover** (Updates, then Refresh),
which is how users will see it. Note the size of the download: it is the
delta from the previous version, and NEXT.md wants the first one recorded.

## 7. Afterwards

- In `../roost`: push the release commit and its tag,
  `git push origin main v0.3.0`. The owner says when.
- Here: record the release in `NEXT.md`, commit and push.
- Roost's `docs/SESSION_LOG.md` gets the session, as its `CLAUDE.md` asks.

## A new application

Before its first release, add `apps/<app-id>.conf` (title, comment,
description, homepage and icon; copy `apps/com.digitalku.roost.conf`), its
icon under `site/icons/`, and a card in `site/index.html`. The app id starts
with `com.digitalku.`. Then the steps above, from 3, with its own build.
