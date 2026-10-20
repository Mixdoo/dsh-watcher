import { spawnSync } from 'node:child_process'

const audit = spawnSync('pnpm', ['audit', '--json'], { encoding: 'utf8' })
const raw = `${audit.stdout || ''}${audit.stderr || ''}`
let report
try {
  report = JSON.parse(audit.stdout || '{}')
} catch {
  report = null
}

const advisories = report?.advisories
  ? Object.values(report.advisories)
  : Array.isArray(report?.vulnerabilities)
    ? Object.values(report.vulnerabilities)
    : []
const lines = ['# Dependency security review', '']
if (!report) {
  lines.push('pnpm audit did not return JSON.')
  lines.push('')
  lines.push('```')
  lines.push(raw.slice(0, 4000))
  lines.push('```')
} else if (advisories.length === 0) {
  const counts = report.metadata?.vulnerabilities
  lines.push(
    counts
      ? `Vulnerabilities: critical ${counts.critical}, high ${counts.high}, moderate ${counts.moderate}, low ${counts.low}, info ${counts.info}. Dependencies scanned: ${report.metadata.totalDependencies}.`
      : 'No advisory records in the audit JSON.',
  )
} else {
  lines.push(`Advisories: ${advisories.length}`)
  lines.push('')
  for (const item of advisories.slice(0, 30)) {
    const title = item.title || item.name || 'advisory'
    const severity = item.severity || item.severity || 'unknown'
    const moduleName = item.module_name || item.name || ''
    lines.push(`- ${severity}: ${moduleName} ${title}`.trim())
  }
}
console.log(lines.join('\n'))
const critical = advisories.some((item) => (item.severity || '').toLowerCase() === 'critical')
if ((audit.status ?? 1) !== 0 && critical) process.exit(audit.status ?? 1)
