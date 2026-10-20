import { spawnSync } from 'node:child_process'

const started = Date.now()
const build = spawnSync('pnpm', ['build'], { stdio: 'inherit' })
const durationMs = Date.now() - started
const budgetMs = 180_000
console.log(`build-duration-ms ${durationMs}`)
console.log(`build-budget-ms ${budgetMs}`)
if ((build.status ?? 1) !== 0) process.exit(build.status ?? 1)
if (durationMs > budgetMs) {
  console.error(`build exceeded ${budgetMs}ms`)
  process.exit(1)
}
