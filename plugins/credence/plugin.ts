import type { PluginLaunchInput, PluginLaunchOutput } from "../../contracts/generated/korrid"

export const name = "credence"
export const title = "Credence"
export const description = "The original village simulation prototype from miniArray."

// Materialized from the actual Nix-packaged launcher, not an invented cartridge.
const release = "@GAME_HASH@"
export const games = {
  credence: {
    title,
    releases: { original: { hashes: [release], file: { packageFile: "launchers", path: "credence" } } },
  },
}
export const runners = {
  credence: { program: "game", releases: [release] },
}

function prepare(input: PluginLaunchInput): PluginLaunchOutput {
  if (input.runnerId !== "@miniarray:credence/credence" || input.corePath !== undefined)
    throw new Error("Unknown Credence runner or unexpected emulator core")
  if (input.contentPath !== input.program)
    throw new Error("Credence requires its own packaged launcher")
  if (input.overrides?.config !== undefined || Object.keys(input.overrides?.settings ?? {}).length > 0)
    throw new Error("Credence implements no launch overrides")
  if ([input.program, input.accountRoot].some(path => !path.startsWith("/") || path.includes("\0")))
    throw new Error("Credence requires absolute paths without NUL bytes")
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
