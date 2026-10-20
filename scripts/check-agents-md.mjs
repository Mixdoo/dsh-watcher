import { readFileSync } from 'node:fs'

const agents = readFileSync(new URL('../AGENTS.md', import.meta.url), 'utf8')
const fence = agents.match(/```commands\n([\s\S]*?)```/)
if (!fence) {
  console.error('AGENTS.md is missing the commands fence')
  process.exit(1)
}
const pkg = JSON.parse(readFileSync(new URL('../package.json', import.meta.url), 'utf8'))
const commands = fence[1]
  .split('\n')
  .map((line) => line.trim())
  .filter(Boolean)
let failed = false
for (const command of commands) {
  const script = command.match(/^pnpm(?: run)? ([A-Za-z0-9:_-]+)$/)
  if (command === 'pnpm install') continue
  if (!script || !pkg.scripts[script[1]]) {
    console.error(`AGENTS.md command is not a package script: ${command}`)
    failed = true
  }
}
const envExample = readFileSync(new URL('../.env.example', import.meta.url), 'utf8')
for (const name of [
  'DSHX_HARNESS',
  'DSH_TEST_URL',
  'DSH_TEST_WORKSPACE',
  'DSH_TEST_SESSION',
  'WATCHER_GOLDEN_DIR',
]) {
  if (!agents.includes(name) || !envExample.includes(name)) {
    console.error(`missing env documentation for ${name}`)
    failed = true
  }
}
if (failed) process.exit(1)
console.log(`agents-md: ${commands.length} commands match package.json`)
