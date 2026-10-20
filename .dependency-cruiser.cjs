/** @type {import('dependency-cruiser').IConfiguration} */
module.exports = {
  forbidden: [
    {
      name: 'observation-stays-below-ui',
      severity: 'error',
      comment: 'Folding and timing must not import the panel, the hub, or pricing.',
      from: { path: '^src/observation' },
      to: { path: '^src/(client|hub|insights)' },
    },
    {
      name: 'insights-stay-off-the-client',
      severity: 'error',
      comment: 'Projection and pricing must not import React panels.',
      from: { path: '^src/insights' },
      to: { path: '^src/client' },
    },
    {
      name: 'hub-stays-off-the-client',
      severity: 'error',
      comment: 'Hub helpers must not import the panel or the pricing engine.',
      from: { path: '^src/hub' },
      to: { path: '^src/(client|insights)' },
    },
  ],
  options: {
    doNotFollow: { path: 'node_modules' },
    tsPreCompilationDeps: true,
  },
}
