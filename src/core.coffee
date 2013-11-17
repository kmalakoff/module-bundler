{spawn} = require 'child_process'
fs = require 'fs'
path = require 'path'
existsSync = fs.existsSync || path.existsSync
wrench = require 'wrench'
coffeescript = require 'coffee-script'
jsp = require("uglify-js").parser
pro = require("uglify-js").uglify

mb = @mb = if (typeof(exports) != 'undefined') then exports else {}
RESERVED = ['_publish', '_load', '_alias']

# add coffeescript compiling
require.extensions['.coffee'] ?= (module, filename) ->
  content = coffeescript.compile fs.readFileSync filename, 'utf8', {filename}
  module._compile content, filename

installThenWriteBundle = (filename, bundle, options, callback) ->
  dir = path.dirname(filename)

  spawned = spawn 'npm', ['install'], {cwd: dir}
  spawned.on 'error', (err) -> console.log "Failed to run command: npm, args: #{['install'].join(', ')}. Error: #{err.message}"
  spawned.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
    callback(false)
  spawned.on 'exit', (code) =>
    callback(false) if (code)

    # TODO: spawn in the package.json directory
    options = clone(options)
    options.skip_install = true
    mb.writeBundle(filename, bundle, options, callback)

mb.writeBundle = (filename, bundle, options, callback) ->
  throw 'module-bundler: missing output filename or object' unless filename
  throw 'module-bundler: missing bundle object' unless bundle
  throw 'module-bundler: missing options.cwd' unless (options and options.cwd)
  throw 'module-bundler: missing callback' unless callback

  # install then bundle
  dir = path.dirname(filename)
  if not options.skip_install and (dir != options.cwd) and existsSync(path.join(dir, 'package.json'))
    installThenWriteBundle(filename, bundle, options, callback)
    return

  bundle_code = mb.generateBundleCode(bundle, options)
  (callback(false); return) unless bundle_code

  # make the destination directory
  resolved_filename = mb.resolveSafe(filename, options);
  try
    directory = path.dirname(resolved_filename)
    wrench.mkdirSyncRecursive(directory, 0o0777) unless existsSync(directory)
  catch e
    throw e if e.code isnt 'EEXIST'

  bundle = "(function() {\n#{bundle_code}})(this);\n"

  # compress the bundle
  if options.compress or resolved_filename.endsWith('.min.js') or resolved_filename.endsWith('-min.js')
    ast = jsp.parse(bundle)
    ast = pro.ast_mangle(ast)
    ast = pro.ast_squeeze(ast)
    compressed_bundle = pro.gen_code(ast)

    # write compressed
    fs.writeFile(resolved_filename, compressed_bundle, 'utf8', -> callback(true))

  # write uncompressed
  else
    fs.writeFile(resolved_filename, bundle, 'utf8', -> callback(true))

mb.writeBundles = (config, options, callback) ->
  throw 'module-bundler: missing config filename or object' unless config
  throw 'module-bundler: missing options.cwd' unless (options and options.cwd)
  throw 'module-bundler: missing callback' unless callback

  # it is a filename so try to load it
  if isString(config)
    try config = require(mb.resolveSafe(config, options)) catch e then (console.log(e.message); return)
    (console.log("mbundle: failed to load #{config} configuration file. Does it exist?"); return) if isString(config) # didn't load

  groupSuccess = true
  count = 1 # start at one in case zero bundles are built
  groupCallback = (success) ->
    groupSuccess &= success
    count--
    callback(groupSuccess) if (count==0)

  # npm packages
  installed_packages = []
  for filename, bundle of config
    count++

    (console.log("mbundle: unexpected information for #{filename}"); count--) unless isObject(bundle)

    # install then bundle
    dir = path.dirname(filename)
    if not options.skip_install and (dir != options.cwd) and existsSync(path.join(dir, 'package.json')) and not installed_packages.contains(path)
      installed_packages.push(path)
      installThenWriteBundle(filename, bundle, options, groupCallback)

    else
      mb.writeBundle(filename, bundle, options, groupCallback)

  # trigger group now in case there were no files (we added 1 above for this purpose)
  groupCallback(true)