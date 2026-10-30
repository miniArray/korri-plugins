import type { PluginLaunchInput, PluginLaunchOutput } from "../../contracts/generated/korrid"

export const name = "rot-and-light"
export const title = "Rot and Light"
export const description = "The original dark-lord and minion-horde prototype from miniArray."

// Materialized from the actual Nix-packaged launcher, not an invented cartridge.
const release = "@GAME_HASH@"
export const games = {
  "rot-and-light": {
    title,
    releases: { original: { hashes: [release], file: { packageFile: "launchers", path: "rot-and-light" } } },
  },
}
export const runners = {
  "rot-and-light": { program: "game", releases: [release] },
}

function prepare(input: PluginLaunchInput): PluginLaunchOutput {
  if (input.runnerId !== "@miniarray:rot-and-light/rot-and-light" || input.corePath !== undefined)
    throw new Error("Unknown Rot and Light runner or unexpected emulator core")
  if (input.contentPath !== input.program)
    throw new Error("Rot and Light requires its own packaged launcher")
  if (input.overrides?.config !== undefined || Object.keys(input.overrides?.settings ?? {}).length > 0)
    throw new Error("Rot and Light implements no launch overrides")
  if ([input.program, input.accountRoot].some(path => !path.startsWith("/") || path.includes("\0")))
    throw new Error("Rot and Light requires absolute paths without NUL bytes")
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
