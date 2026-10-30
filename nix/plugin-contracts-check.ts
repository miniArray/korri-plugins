import assert from "node:assert/strict"
import { spawnSync } from "node:child_process"
import { existsSync, mkdtempSync, readFileSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import type { PluginLaunchInput } from "../contracts/generated/korrid"
import * as eggshell from "../plugins/eggshell/plugin"

const [host, korrid, recordArguments, ...packages] = process.argv.slice(2)
assert.equal(packages.length, 4)
let eggshellPackage: string | undefined
for (const packagePath of packages) {
  const manifest = JSON.parse(readFileSync(join(packagePath, "manifest.json"), "utf8"))
  const plugin = await import(join(packagePath, manifest.entry))
  assert.deepEqual(manifest.publisher, { namespace: "@miniarray" })
  for (const [key, runner] of Object.entries(plugin.runners)) {
    assert.equal(Object.hasOwn(runner as object, "id"), false, `${plugin.name}/${key}: derived runner ID`)
  }
  for (const [key, system] of Object.entries(plugin.systems ?? {})) {
    assert.equal(Object.hasOwn(system as object, "id"), false, `${key}: derived system ID`)
  }
  const admission = spawnSync(host, ["seed", packagePath, "https://miniarray.github.io/korri-plugins/"], { encoding: "utf8" })
  assert.equal(admission.status, 0, admission.stderr)
  assert.equal(JSON.parse(admission.stdout).id, `@miniarray:${plugin.name}`)
  if (plugin.name === "eggshell") eggshellPackage = packagePath
  console.log(`CONTRACT-VERIFIED ${plugin.name}`)
}

assert.deepEqual(eggshell.systems, {
  eggshell: { title: "Eggshell", content: { extensions: ["json"] } },
})
assert.deepEqual(eggshell.runners, {
  eggshell: { program: "eggshell", systems: ["eggshell"] },
})
const account = join(mkdtempSync(join(tmpdir(), "eggshell-check-")), "Player '; $(exit 21)")
const input: PluginLaunchInput = {
  runnerId: "@miniarray:eggshell/eggshell",
  program: recordArguments,
  contentPath: "/library/Level '; $(exit 19).json",
  accountRoot: account,
  saveRoot: `${account}/saves/level`,
  cacheRoot: "/cache",
  files: {},
  artifacts: {},
}
const args = ["--fullscreen", "--", `--level-code=${input.contentPath}`, `--save-dir=${input.saveRoot}`]
assert.deepEqual(eggshell.handlers["launch.prepare"](input), {
  command: recordArguments,
  args,
  env: { HOME: account },
  envUnset: ["XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"],
  cwd: account,
  directories: [account, input.saveRoot],
})
assert.ok(eggshellPackage)
const run = spawnSync(korrid, [
  "plugin-run", join(eggshellPackage, "plugin.ts"), JSON.stringify(input),
  JSON.stringify({ modifiers: [] }), "eggshell-check",
], { encoding: "utf8" })
assert.equal(run.status, 0, run.stderr)
assert.equal(run.stdout, args.join("\0") + "\0")
assert.ok(existsSync(input.saveRoot))
for (const unsupported of [
  { runnerId: "@miniarray:other/eggshell" },
  { corePath: "/core.so" },
  { contentPath: undefined },
  { contentPath: "relative.json" },
  { saveRoot: "/tmp/with\0nul" },
  { overrides: { config: {} } },
  { overrides: { settings: { unknown: true } } },
]) {
  assert.throws(() => eggshell.handlers["launch.prepare"]({ ...input, ...unsupported } as PluginLaunchInput))
}
console.log("Eggshell launch plan, refusals and real plugin-run passed")
