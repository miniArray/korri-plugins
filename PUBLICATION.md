# Signed cache publication

The cache is `https://miniarray.github.io/korri-plugins/`. GitHub Pages serves
`nix-cache-info` and signed narinfos from `cache-index`. NARs, architecture path
lists, exact source revisions and offline metadata stay in `build-*` releases.
The old `cache` release is frozen and retained for old receipts and rollback.
The existing `miniarray-plugins-1` signing key stays unchanged.

`nix/publish-cache.sh` pins the shared `korri-os/plugins` publisher to a full
tested commit. There is no local copy of that tool. It requires a clean source
tree and a full `EXPECTED_SOURCE_SHA`. Run it on a build machine, never a device.
Resolve the tested source tag to a full SHA, and pin both dry-run and publication
checkouts to that tag. Before building or uploading, check:

```sh
test "$(git rev-parse HEAD)" = "$EXPECTED_SOURCE_SHA"
```

Use `build --system SYSTEM --paths-file PATHS korri-plugin-eggshell` for each
architecture. Export only the resulting approved package paths with the existing
key. Prepare each architecture separately, with its path list and revision,
then use `combine`. Follow the shared publisher's
[publication guide](https://github.com/korri-os/plugins/blob/8562bb480a211033426894a94c69c97a83a5aa0f/PUBLICATION.md).

After publication approval:

```sh
bash nix/publish-cache.sh publish prepared \
  --repo miniArray/korri-plugins --tag "$NAR_TAG" \
  --index-branch cache-index \
  --cache-url https://miniarray.github.io/korri-plugins/ \
  --revision "$EXPECTED_SOURCE_SHA"
```

The NAR tag must already point at the tested full SHA. The publisher verifies
payload assets before appending metadata, dispatches `cache-pages.yml`, and
checks exact served bytes before reporting success. Retain architecture-specific
offline archives and source evidence. Store private keys only in the approved
local key file or `NIX_CACHE_SIGNING_KEY` secret, never in Git or the Nix store.

Initial migration copies the existing public metadata files unchanged.
No binary payload moves or needs re-signing. Future counts can grow in the Pages
index without consuming assets in one metadata release. GitHub repository,
Pages and per-batch release limits still apply.

A device must separately approve its new exact publisher binding and receipt
digests. Reboot alone does not roll back migrated receipts. The Core one-off
migration restores both the old bindings and exact receipt backups on failure.
This repository update grants no device permissions or game-content rights.
