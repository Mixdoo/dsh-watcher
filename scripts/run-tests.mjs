import { spawnSync } from 'node:child_process'

const coverage = process.argv.includes('--coverage')
const args = ['exec', 'vitest', 'run', '--reporter=verbose']
if (coverage) args.push('--coverage')

const started = Date.now()
const result = spawnSync('pnpm', args, { stdio: 'inherit' })
const durationMs = Date.now() - started
console.log(`test-suite-duration-ms ${durationMs}`)
process.exit(result.status ?? 1)
