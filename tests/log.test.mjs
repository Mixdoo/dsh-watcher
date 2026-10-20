import assert from 'node:assert/strict'
import { test } from 'vitest'
import { redact } from '../lib/types/log.js'

test('redact hides tokens in errors and query strings', () => {
  const scrubbed = redact('startup failed token=dsh_live_secret&ok query ?token=abc123')
  assert.equal(scrubbed.includes('dsh_live_secret'), false)
  assert.equal(scrubbed.includes('abc123'), false)
  assert.match(scrubbed, /token=\[redacted\]/)
  assert.match(scrubbed, /token=\[redacted\]/)
  const errorText = redact(new Error('bearer: hunter2'))
  assert.equal(errorText.includes('hunter2'), false)
  assert.match(errorText, /bearer:\s*\[redacted\]/)
})
