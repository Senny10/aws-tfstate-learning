const path = require('path')
const esbuild = require('esbuild')

esbuild.build({
  entryPoints: [ './handler.ts' ],
  bundle: true,
  outdir: path.join(__dirname, 'dist'),
  outbase: './',
  platform: 'node',
  sourcemap: true,
})
