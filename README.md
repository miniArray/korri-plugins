# miniArray Korri plugins

Korri plugins published under the `@miniarray` namespace. Devices must bind
that namespace to this repository's signing key and cache before they install
anything from here. A binding grants no permissions; every install still needs
the owner's exact approval digest.

| Output | Plugin | Platforms |
|---|---|---|
| `korri-plugin-eggshell` | `@miniarray:eggshell`, the [Eggshell](https://github.com/miniArray/eggshell) level player | x86_64 and aarch64 Linux |

## Publisher binding

```nix
services.korri.pluginHost.publishers."@miniarray" = {
  publicKey = "miniarray-plugins-1:4p6fkCeEKBzk58bvj2bIWHFDQzs+6ADZD20z7a9hnjs=";
  cacheUrl = "https://github.com/miniArray/korri-plugins/releases/download/cache/";
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

## Build and publish

Run on a build machine, never a target device. ARM outputs need an aarch64
builder.

```sh
nix build --no-link .#packages.x86_64-linux.korri-plugin-eggshell
nix build --no-link .#packages.aarch64-linux.korri-plugin-eggshell
```

The signed cache uses the standard Nix file-cache format, published as GitHub
release assets: a mutable `cache` release holds `nix-cache-info` and signed
`.narinfo` files, and one `build-<commit>` release per batch holds the NARs.
Paths already on cache.nixos.org are omitted. Publication uses korri-os/plugins'
`nix/github-cache.py` (`export`, `prepare --upstream https://cache.nixos.org/`,
`publish`). The private signing key is the `NIX_CACHE_SIGNING_KEY` secret and
never enters Git or the Nix store.
