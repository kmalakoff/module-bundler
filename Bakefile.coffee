module.exports =
  library:
    join: 'module-bundler.js'
    files: [
      'src/helpers.coffee'
      'src/core.coffee'
      'src/resolve.coffee'
      'src/js-generators.coffee'
    ]
    _build:
      commands: [
        'cp module-bundler.js packages/npm/module-bundler.js'
        'cp README.md packages/npm/README.md'
        'cp bin/mbundle packages/npm/bin/mbundle'
      ]

  tests:
    directories: 'test/core'
    _build:
      output: 'build'
    _test:
      command: 'nodeunit'
      files: '**/*.js'
