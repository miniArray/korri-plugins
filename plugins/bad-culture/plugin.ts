import type { PluginLaunchInput, PluginLaunchOutput } from "../../contracts/generated/korrid"

export const name = "bad-culture"
export const title = "Bad Culture"
export const description = "The original falling-capsule puzzle game from miniArray."

// Materialized from the actual Nix-packaged launcher, not an invented cartridge.
const release = "@GAME_HASH@"
export const games = {
  "bad-culture": {
    title,
    releases: { original: { hashes: [release], file: { packageFile: "launchers", path: "bad-culture" } } },
  },
}
export const runners = {
  "bad-culture": { program: "game", releases: [release] },
}

function prepare(input: PluginLaunchInput): PluginLaunchOutput {
  if (input.runnerId !== "@miniarray:bad-culture/bad-culture" || input.corePath !== undefined)
    throw new Error("Unknown Bad Culture runner or unexpected emulator core")
  if (input.contentPath !== input.program)
    throw new Error("Bad Culture requires its own packaged launcher")
  if (input.overrides?.config !== undefined || Object.keys(input.overrides?.settings ?? {}).length > 0)
    throw new Error("Bad Culture implements no launch overrides")
  if ([input.program, input.accountRoot].some(path => !path.startsWith("/") || path.includes("\0")))
    throw new Error("Bad Culture requires absolute paths without NUL bytes")
  return {
    command: input.program,
    args: ["--fullscreen"],
    env: { HOME: input.accountRoot },
    envUnset: ["XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"],
    cwd: input.accountRoot,
    directories: [input.accountRoot],
  }
}
export const handlers = { "launch.prepare": prepare }
