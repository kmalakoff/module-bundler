module.exports =
  library:
    join: 'module-bundler.js'
    files: [
      'src/module-bundler/helpers.coffee'
      'src/module-bundler/core.coffee'
      'src/module-bundler/resolve.coffee'
      'src/module-bundler/js-generators.coffee'
    ]
    modes:
      build:
        commands: [
          'cp module-bundler.js packages/npm/module-bundler.js'
        ]

  mbundle:
    output: 'lib'
    files: 'src/mbundle.coffee'
    modes:
      build:
        commands: [
          'cp lib/mbundle.js packages/npm/lib/mbundle.js'
          'cp bin/mbundle packages/npm/bin/mbundle'
        ]

  tests:
    output: 'build'
    directories: 'test/core'
    modes:
      test:
        command: 'nodeunit'
        files: '**/*.js'
