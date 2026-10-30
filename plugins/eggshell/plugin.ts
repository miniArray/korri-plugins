import type {
  PluginLaunchInput,
  PluginLaunchOutput,
} from "../../contracts/generated/korrid"

export const name = "eggshell"
export const title = "Eggshell"
export const description =
  "Plays level JSON files in Eggshell, with resumable saves in Korri save storage."

// Owner decision 2026-10-23: Eggshell levels are `.json` files. Discovery only
// scans folders explicitly paired with this system, so other JSON elsewhere is
// not claimed. A JSON file that is not a level fails to load and reports why.
export const systems = {
  eggshell: {
    title: "Eggshell",
    content: { extensions: ["json"] },
  },
}

export const runners = {
  eggshell: {
    program: "eggshell",
    systems: ["eggshell"],
  },
}

function prepareLaunch(input: PluginLaunchInput): PluginLaunchOutput {
  if (input.runnerId !== "@miniarray:eggshell/eggshell") {
    throw new Error("Unknown Eggshell runner")
  }
  if (input.corePath !== undefined) {
    throw new Error("Eggshell is a standalone player and loads no emulator core")
  }
  if (
    input.overrides?.config !== undefined ||
    Object.keys(input.overrides?.settings ?? {}).length > 0
  ) {
    throw new Error("Eggshell does not implement Korri launch overrides")
  }
  // Provider-ref routes carry no file. Eggshell always loads one level.
  const contentPath = input.contentPath
  if (contentPath === undefined) {
    throw new Error("Eggshell requires a level file")
  }
  if (
    [input.program, contentPath, input.accountRoot, input.saveRoot].some(
      path => !path.startsWith("/") || path.includes("\0"),
    )
  ) {
    throw new Error("Eggshell requires absolute program, level and save paths without NUL bytes")
  }
  // Godot reads options after `--` as game arguments. The level and its
  // autosave stay separate: the level is read-only, saves go to saveRoot.
  return {
    command: input.program,
    args: [
      "--fullscreen",
      "--",
      `--level-code=${contentPath}`,
      `--save-dir=${input.saveRoot}`,
    ],
    // Keep Godot's own user:// data and logs in account storage, not the host's home.
    env: { HOME: input.accountRoot },
    envUnset: ["XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"],
    cwd: input.accountRoot,
    directories: [input.accountRoot, input.saveRoot],
  }
}

export const handlers = {
  "launch.prepare": prepareLaunch,
}
