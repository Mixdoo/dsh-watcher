import { readdirSync, readFileSync, statSync } from 'node:fs'
import { join } from 'node:path'

const roots = ['src', 'tests', 'scripts', 'tools']
const marker = /\b(?:TODO|FIXME|HACK|XXX)\b/
const ticket = /\b(?:TODO|FIXME|HACK|XXX)\s*\(#\d+\)/
const offenders = []

function walk(directory) {
  for (const name of readdirSync(directory)) {
    const path = join(directory, name)
    const info = statSync(path)
    if (info.isDirectory()) {
      walk(path)
      continue
    }
    if (name === 'check-todos.mjs') continue
    if (!/\.(?:ts|tsx|mjs|js|yml|md)$/.test(name)) continue
    const lines = readFileSync(path, 'utf8').split('\n')
    lines.forEach((line, index) => {
      if (marker.test(line) && !ticket.test(line)) offenders.push(`${path}:${index + 1}`)
    })
  }
}

for (const root of roots) walk(root)
if (offenders.length > 0) {
  console.error('Tech debt markers need an issue number, for example TODO(#12):')
  for (const offender of offenders) console.error(offender)
  process.exit(1)
}
console.log('todo-scan: every TODO/FIXME/HACK/XXX cites an issue, or none exist')
