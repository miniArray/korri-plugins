# miniArray Korri plugins

Korri plugins published under the `@miniarray` namespace. Devices must bind
that namespace to this repository's signing key and cache before they install
anything from here. A binding grants no permissions; every install still needs
the owner's exact approval digest.

| Output | Plugin | Platforms |
|---|---|---|
| `korri-plugin-eggshell` | `@miniarray:eggshell`, the [Eggshell](https://github.com/miniArray/eggshell) level player | x86_64 and aarch64 Linux |
| `korri-plugin-bad-culture` | `@miniarray:bad-culture`, [Bad Culture](https://github.com/miniArray/bad-culture) | x86_64 and aarch64 Linux |
| `korri-plugin-credence` | `@miniarray:credence`, [Credence](https://github.com/miniArray/credence) | x86_64 and aarch64 Linux |
| `korri-plugin-rot-and-light` | `@miniarray:rot-and-light`, [Rot and Light](https://github.com/miniArray/rot-and-light) | x86_64 and aarch64 Linux |

## Publisher binding

```nix
services.korri.pluginHost.publishers."@miniarray" = {
  publicKey = "miniarray-plugins-1:4p6fkCeEKBzk58bvj2bIWHFDQzs+6ADZD20z7a9hnjs=";
  cacheUrl = "https://miniarray.github.io/korri-plugins/";
};
```

## Eggshell

The runner `@miniarray:eggshell/eggshell` claims `.json` files in library
folders paired with the `eggshell` system. Each file is one level. The game
receives the level path and the per-game Korri save root; its resumable
autosave lives there. Godot's own data and logs use the account root.

The package exports `eggshell.pck` once on x86_64 and runs it on the same
Godot version from nixpkgs (4.7.2). On aarch64 it uses GLES compatibility
rendering. Nothing builds on a device. The aarch64 closure is about 1.2 GB,
almost all of it the Godot runtime, which devices fetch from cache.nixos.org.

## Native games

The three native-game plugins declare their own packaged games and hash-bound
runners through Core's existing contracts. They need no imported content file
or new system. Their immutable launcher is the declared release file. Enabled
plugins contribute their own game to the library. This does not enable or
install anything on a device.

Each package includes accessible original-work, engine and dependency notices.
The Rust games also include the exact covered dependency source archives.
[Native game packaging](plugins/NATIVE-GAMES.md) records source pins, contract
grounding, rights limits and the headless verification boundary. No original
work is relicensed as open source.

## Build and publish

Run on a build machine, never a target device. ARM outputs need an aarch64
builder.

```sh
nix build --no-link .#packages.x86_64-linux.korri-plugin-eggshell
nix build --no-link .#packages.aarch64-linux.korri-plugin-eggshell
```

The new native packages have matching output names in the table above. Run
`nix flake check` on x86_64-linux and build every `korri-plugin-*` package for
aarch64-linux before publication. Run the corresponding aarch64-linux checks
where supported. `plugin-contracts` typechecks all four plugins against the
pinned Core contract, checks derived-ID declarations and real host admission,
and exercises Eggshell's launch plan and real korrid `plugin-run` path.
`native-games` uses the real host and korrid sandbox plus headless game smoke
checks. Neither check proves physical device behavior.

Core derives runner IDs as `<pluginId>/<key>` and system IDs as their map keys.
Do not author runner or system `id` fields (ADR 0045).

The signed cache uses the standard Nix file-cache format. GitHub Pages serves
`nix-cache-info` and signed `.narinfo` files from `cache-index`. One
`build-<commit12>` release per batch holds NAR payloads and architecture-specific
offline metadata. Existing NARs do not move. The old `cache` release stays frozen
and readable for old receipts and rollback.

Paths already on cache.nixos.org are omitted. All plugin repositories use the
same publisher from korri-os/plugins, not separately maintained copies.
[PUBLICATION.md](PUBLICATION.md) pins the tool and describes publication.
The private signing key is the `NIX_CACHE_SIGNING_KEY` secret and never enters
Git or the Nix store. Updating a device's exact bound URL requires a separate
reviewed receipt migration; changing this README grants no device approval.
