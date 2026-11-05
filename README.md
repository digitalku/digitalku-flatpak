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
| `scripts/` | `init.sh`, `publish.sh`, `refs.sh`, `upload.sh`, `pull.sh`; `serve.sh` and `test-key.sh` for local tests; `lib.sh` is shared |
| `keys/` | The public half of the signing key, once it exists, and how to make it ([keys/README.md](keys/README.md)) |
| `site/` | The landing page and the icons, uploaded to the bucket's root beside the repository |
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
- **Fixed for good on 2026-11-05.** The remote's name `digitalku`, its address
  `https://flatpak.digitalku.com` and the branch `stable` are written into
  every installed copy, and none of them can change without each user
  installing again. The owner confirmed all three before the first release.
- **No collection id.** It would only serve installs copied over USB or a
  local network, which nobody has asked for. Decided 2026-11-05.
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

## 4. Uploading

`scripts/upload.sh` sends `public/` to the R2 bucket through the AWS CLI. It
uses R2's S3 API, so no new tool is needed. It deletes nothing, and it goes in
an order a client cannot see half of:

1. `objects/`, `deltas/`, `delta-indexes/` and `summaries/`. Their names are
   hashes of their content, so they never change. They are synced (only what
   the bucket lacks) with `Cache-Control: public, max-age=31536000, immutable`.
2. `refs/` and `config`, always sent, `no-cache`.
3. `summary` and `summary.idx`, **last**, each just after its `.sig`. They are
   `no-cache`.
4. The `.flatpakrepo` and `.flatpakref` files, `no-cache`, typed
   `application/vnd.flatpak.repo` and `application/vnd.flatpak.ref` so a
   browser hands them to the software centre.
5. `site/`, if it exists: icons and a landing page, `max-age=300`.

It refuses a tree that was written for another address, and once
`keys/digitalku.asc` exists, a tree carrying any other key. A local test
cannot be uploaded to the real bucket by mistake. `--dry-run` lists what
would go.

`build-update-repo` deletes deltas that have been superseded from `public/`,
and `upload.sh` leaves them in the bucket. They cost a little storage and
nothing else.

`public/` is the working copy the next publish builds on. On a machine
without one, or with an older one, run `scripts/pull.sh` first. Publishing
onto a stale copy makes a commit whose parent is not the remote's latest.

### Setting up the bucket (owner, once)

1. In Cloudflare, create the R2 bucket `digitalku-flatpak`.
2. Bucket → Settings → Custom Domains → connect `flatpak.digitalku.com`. The
   `digitalku.com` zone must be on Cloudflare for this. Leave the `r2.dev`
   address off.
3. One Cache Rule for the whole host, `(http.host eq "flatpak.digitalku.com")`:
   **Eligible for cache**, Edge TTL **use the cache-control header if present,
   bypass if not**, Browser TTL **respect origin**. The headers `upload.sh`
   sets then decide everything: the hashed files are cached for a year, the
   `no-cache` ones are revalidated with R2 on every request, and the site
   lives five minutes. Without the Browser TTL setting, the zone's own
   default (six months on digitalku.com) replaced the site's five minutes,
   which the first test upload found. Check it with a `GET`
   (`curl -s -o /dev/null -D - URL`): a `HEAD` from `curl -I` reports
   `cf-cache-status: DYNAMIC` whatever the rule says, and a second `GET`
   should report `HIT`.
4. A URL Rewrite Rule (Rules → Overview → Create rule → URL Rewrite Rule),
   because R2 has no index document: when `(http.host eq
   "flatpak.digitalku.com" and http.request.uri.path eq "/")`, rewrite the
   **path** statically to `index.html` (the field supplies the leading `/`)
   and **preserve** the query. Rewriting the query instead is the easy
   mistake, and the dashboard's list then says *Rewrite query to*. Without
   the rule, `https://flatpak.digitalku.com/` is a 404.
5. R2 → Manage API tokens → a token with **Object Read & Write** on that
   bucket only. Then `aws configure --profile digitalku-r2`, with the
   token's access key and secret and region `auto`. The secret stays in
   `~/.aws/credentials`.
6. Set `R2_ENDPOINT=https://<account-id>.r2.cloudflarestorage.com` in
   `remote.conf`.

### The first real publish

After the key ([keys/README.md](keys/README.md)) and the bucket exist:

```sh
rm -rf public                         # the test tree; it was never uploaded
scripts/init.sh
scripts/publish.sh com.digitalku.roost ../roost/scratch/flatpak/repo
scripts/upload.sh
flatpak install --user --from https://flatpak.digitalku.com/com.digitalku.roost.flatpakref
```

A copy of Roost installed from the GitHub bundle (origin `roost-origin`,
branch `master`) is not moved onto the remote by any of this. Uninstall it
and install from the `.flatpakref`. Library data lives outside the
installation and stays.

## 5. Trying it locally

None of this needs the real key or the bucket. A test key, and
[moto](https://github.com/getmoto/moto) in a venv standing in for R2:

```sh
scripts/test-key.sh > scratch/env.sh          # a throwaway key in scratch/gnupg
cat >> scratch/env.sh <<'END'
export DKF_REMOTE_NAME=digitalku-test
export DKF_BASE_URL=http://127.0.0.1:5055/digitalku-flatpak
export DKF_R2_ENDPOINT=http://127.0.0.1:5055 DKF_AWS_PROFILE=
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test
export DKF_ALLOW_TEST_KEY=1
END
. scratch/env.sh

python3 -m venv scratch/venv && scratch/venv/bin/pip install 'moto[server]'
scratch/venv/bin/moto_server -H 127.0.0.1 -p 5055 &
aws --endpoint-url $DKF_R2_ENDPOINT --region auto s3 mb s3://digitalku-flatpak
aws --endpoint-url $DKF_R2_ENDPOINT --region auto s3api put-bucket-policy \
  --bucket digitalku-flatpak --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::digitalku-flatpak/*"}]}'

scripts/init.sh
scripts/publish.sh com.digitalku.roost ../roost/scratch/flatpak/repo
scripts/upload.sh

# A separate user installation, so the machine's own is untouched. It uses the
# system's runtimes where they are installed. Export it only for flatpak
# itself: the scripts run ostree from the org.flatpak.Builder installed in the
# real one.
FLATPAK_USER_DIR=$PWD/scratch/flatpak-user \
  flatpak --user install --from $DKF_BASE_URL/com.digitalku.roost.flatpakref
```

`scripts/serve.sh` serves `public/` directly, without a bucket, for a test of
the repository alone.

What the prototype has shown so far:

- **2026-11-05, from `public/` served directly.** Roost installed from its
  `.flatpakref` with signature checking on. A second commit reached the
  installed copy as an update through a static delta. A summary signed by
  another key was refused.
- **2026-11-05, through the bucket.** Uploaded to moto, Roost installed from
  the bucket. `pull.sh` then brought it into an empty `public/`, a third
  commit was published onto that copy, and the installed copy updated to it,
  with the second commit as its parent. `upload.sh` refused a tree with a
  stale URL, and a test key without `DKF_ALLOW_TEST_KEY`. A keyring holding
  only the signing subkey signed a summary that verified against the public
  block.

## 6. The site

`site/index.html` is the page at `https://flatpak.digitalku.com/`. It is one
file with no external requests, in light and dark, and it lists each
application with an **Install** link to its `.flatpakref` and the same as a
command. **A new application is added to it by hand**, beside its
`apps/<app-id>.conf`.

| File | Used by |
| --- | --- |
| `digitalku.png` | `Icon=` in the `.flatpakrepo` (512×512, from digitalku.com's favicon) |
| `favicon.ico` | The page; made from `digitalku.png` with ImageMagick |
| `digitalku-logo.svg`, `digitalku-logo-dark.svg` | The page's header; the dark one is the same file with the navy `#05396b` turned to `#e6edf5` |
| `icons/<app-id>.png` | `Icon=` in that application's `.flatpakref` (256×256) |
| `icons/<app-id>.svg` | The page |

Roost's icons are copies of `assets/brand/icon-256.png` and `roost-icon.svg`
in the Roost repository. When the brand changes there, copy them again.

## 7. Not done yet

- The first real publish (§4).
- Roost's ADR-0063 §10 still says the Flatpak ships as a bundle on GitHub
  Releases.
