{spawn} = require 'child_process'
path = require 'path'

root = if (typeof(window) != 'undefined') then window else global
PROJECT_ROOT = "#{__dirname}/../../.."
SAMPLE_LIBRARY_ROOT = "#{__dirname}/../../sample_library/"

# ModuleBundler
mb = if (typeof(require) != 'undefined') then require("#{PROJECT_ROOT}/module-bundler") else @mb

check_bundle = (test, bundle) ->
  # bundled from file
  test_load_test = bundle.require('load_test')
  test.ok(!!test_load_test, 'load_test was bundled from a file')

  # bundled from npm
  test_wrench = bundle.require('wrench')
  test.ok(!!test_wrench, 'wrench was bundled')

  # alias
  test_wrench = bundle.require('wrench-alias')
  test.ok(!!test_wrench, 'wrench was aliased')

  # publish
  test.ok(!!root['wrench-publish'], 'wrench was published')

  # loaded
  test.ok(!!root['load_test'], 'load_test was loaded')

clean_bundle = ->
  delete root['wrench-publish']
  delete root['_']

exports.require_bundler_core =
  'TEST DEPENDENCY MISSING': (test) ->
    test.ok(not !mb)
    spawned = spawn 'npm', ['install'], {cwd: SAMPLE_LIBRARY_ROOT}
    spawned.on 'exit', (code) =>
      test.done()

  'mb.writeBundleSync (CoffeeScript config file pre-loaded)': (test) ->
    out_filename = path.join(SAMPLE_LIBRARY_ROOT, 'build/bundle-coffeescript.js')
    config = require(path.join(SAMPLE_LIBRARY_ROOT, 'bundle-config-test.coffee'))
    mb.writeBundlesSync(config, {cwd: SAMPLE_LIBRARY_ROOT})

    # check expected state and clean up after test
    check_bundle(test, require(out_filename))
    clean_bundle()

    test.done()

  'mb.writeBundleSync (JavaScript config file by name)': (test) ->
    out_filename = path.join(SAMPLE_LIBRARY_ROOT, 'build/bundle-javascript.js')
    filename = path.join(SAMPLE_LIBRARY_ROOT, 'bundle-config-test.js')
    mb.writeBundlesSync(filename, {cwd: SAMPLE_LIBRARY_ROOT})

    # check expected state and clean up after test
    check_bundle(test, require(out_filename))
    clean_bundle()

    test.done()

  'mb.resolveSafe': (test) ->
    sample_library_dir = path.normalize(SAMPLE_LIBRARY_ROOT)
    project_dir = path.normalize(PROJECT_ROOT) + '/'

    load_test_path = mb.resolveSafe('vendor/load_test.js', {cwd: SAMPLE_LIBRARY_ROOT})
    test.ok(load_test_path.replace(sample_library_dir, '') == 'vendor/load_test.js', 'should find load_test.js')

    load_test_path = mb.resolveSafe('file://vendor/load_test.js', {cwd: SAMPLE_LIBRARY_ROOT})
    test.ok(load_test_path.replace(sample_library_dir, '') == 'vendor/load_test.js', 'should find load_test.js with file:// disabuguation')

    load_test_path = mb.resolveSafe('file://vendor/load_test.js', {cwd: SAMPLE_LIBRARY_ROOT})
    test.ok(load_test_path.replace(sample_library_dir, '') == 'vendor/load_test.js', 'should find load_test.js with file:// disabuguation')

    wrench_path = mb.resolveSafe('wrench', {cwd: SAMPLE_LIBRARY_ROOT})
    test.ok(wrench_path.replace(project_dir, '') == 'node_modules/wrench/lib/wrench.js', 'should find wrench in node_modules')

    wrench_path = mb.resolveSafe('wrench', {cwd: SAMPLE_LIBRARY_ROOT, skip_require: true, must_exist: true})
    test.ok(!wrench_path, 'should not find wrench since skipping require node_modules')

    test.done()

  'Error cases': (test) ->
    # TODO
    test.done()