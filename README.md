# Digitalku Flatpak remote

The Flatpak repository every Linux application Digitalku distributes is
installed and updated from: `https://flatpak.digitalku.com`, added on a user's
machine as the remote `digitalku`.

It exists because a `.flatpak` bundle on a releases page has no update path,
and Flathub is not an option for applications written with AI assistance (its
Generative AI policy). A remote of our own gives updates through GNOME Software,
Discover and `flatpak update`, with nothing in the applications that phones
home. Runtimes still come from Flathub, through `RuntimeRepo=` in each
`.flatpakref`. Only the applications are served from here.

## 1. Layout

| Path | Holds |
| --- | --- |
| `remote.conf` | The remote's name, URL, branch, descriptive fields and signing key |
| `apps/<app-id>.conf` | One file per published application: the fields of its `.flatpakref` |
| `scripts/` | `init.sh`, `publish.sh`, `refs.sh`, `serve.sh`, `test-key.sh`; `lib.sh` is shared |
| `keys/` | The public half of the signing key, once it exists ([keys/README.md](keys/README.md)) |
| `public/` | **Not in git.** What is served: `repo/` (OSTree, `archive-z2`), `digitalku.flatpakrepo`, one `<app-id>.flatpakref` per application |
| `scratch/` | **Not in git.** Test keys, test installations |

Served as:

```
https://flatpak.digitalku.com/repo/                     the OSTree repository
https://flatpak.digitalku.com/digitalku.flatpakrepo     adds the remote
https://flatpak.digitalku.com/com.digitalku.roost.flatpakref
```

## 2. The rules

- **Everything is signed.** Commits and the summary, by one GPG key whose
  public half is embedded in every `.flatpakrepo` and `.flatpakref`. Nothing is
  ever published for `--no-gpg-verify`.
- **The repository is appended to, never rebuilt.** `publish.sh` commits a
  build *on top of* the branch the remote already holds, so an installed copy
  sees a child commit and fetches a static delta. A fresh repository would
  give every installed copy an unrelated history. `init.sh` runs once.
- **One branch: `stable`.** Whatever branch the build used (`master` by
  default), it is published as `stable`.
- **An application is listed before it is published.** `publish.sh` refuses an
  app id with no `apps/<app-id>.conf`.

## 3. Publishing a release

Build the application with `flatpak-builder --repo=<dir>`. For Roost that is
`packaging/flatpak/build-local.sh`, which leaves its repository at
`scratch/flatpak/repo`. Then:

```sh
scripts/publish.sh com.digitalku.roost ../roost/scratch/flatpak/repo
```

`publish.sh` does the following:

1. Commits that build as `app/<app-id>/<arch>/stable` (`flatpak build-commit-from`), signed.
2. Regenerates the summary, the appstream branch and the static deltas
   (`flatpak build-update-repo`).
3. Rewrites the `.flatpakrepo` and `.flatpakref` files (`refs.sh`).

`--with-debug` publishes the `.Debug` extension as well. `--subject` sets the
commit message. `--force` commits a tree identical to the last one, which is
for re-signing and never for a release.

## 4. Uploading — not built yet

The copy of record will be the Cloudflare R2 bucket behind
`flatpak.digitalku.com`. Two things must hold when that is built:

- **Order.** Upload `objects/` and `deltas/` first, then `refs/`, and
  `summary`, `summary.sig`, `summary.idx`, `summary.idx.sig`, `summaries/`
  and `config` **last**. A client that reads a new summary before its objects
  have arrived fails the update.
- **Caching.** `summary*`, `summaries/`, `config` and `refs/` are uncached.
  `objects/` and `deltas/` are immutable, because their names are hashes of
  their content.

`public/` is the working copy the next publish builds on. Keep it, or pull it
back from the bucket before publishing from another machine.

## 5. Trying it locally

Nothing here needs the real key or the bucket:

```sh
scripts/test-key.sh > scratch/env.sh              # a throwaway key in scratch/gnupg
. scratch/env.sh
export DKF_BASE_URL=http://127.0.0.1:8080 DKF_REMOTE_NAME=digitalku-test
scripts/init.sh
scripts/publish.sh com.digitalku.roost ../roost/scratch/flatpak/repo
scripts/serve.sh &                                 # loopback only

# A separate user installation, so the machine's own is untouched. It uses the
# system's runtimes where they are installed.
export FLATPAK_USER_DIR=$PWD/scratch/flatpak-user
flatpak --user install --from http://127.0.0.1:8080/com.digitalku.roost.flatpakref
flatpak --user update
```

The prototype on 2026-11-05 ran exactly this. It installed Roost from the remote
with signature checking on, published a second commit that installed copies
updated to through a static delta, and found that a summary signed by any other
key is refused.

## 6. Not done yet

- The real signing key ([keys/README.md](keys/README.md)). `GPG_KEY_ID` in
  `remote.conf` is empty until it exists.
- The upload to R2 and the bucket's cache rules (§4).
- The icons the `.flatpakrepo` and `.flatpakref` point at (`digitalku.svg`,
  `icons/com.digitalku.roost.png`), and a landing page at the root.
- A collection id. Without one, the remote cannot be used for peer-to-peer or
  USB installs. It can be added later, but every installed copy then has to be
  told about it.
- Roost's ADR-0063 §10 still says the Flatpak ships as a bundle on GitHub
  Releases.
