{spawn} = require 'child_process'
fs = require 'fs'
path = require 'path'
_ = require 'underscore'
existsSync = fs.existsSync || path.existsSync
wrench = require 'wrench'
coffeescript = require 'coffee-script'
jsp = require('uglify-js').parser
pro = require('uglify-js').uglify
Queue = require 'queue-async'

mb = @mb = if (typeof(exports) != 'undefined') then exports else {}
RESERVED = ['_publish', '_load', '_alias']

# add coffeescript compiling
require.extensions['.coffee'] ?= (module, filename) ->
  content = coffeescript.compile fs.readFileSync filename, 'utf8', {filename}
  module._compile content, filename

installThenWriteBundle = (filename, bundle, options, callback) ->
  dir = path.dirname(filename)

  spawned = spawn 'npm', ['install'], {cwd: dir}
  spawned.on 'error', (err) -> console.log "Failed to run command: npm, args: #{['install'].join(', ')}. Error: #{err.message}"; callback(err)
  spawned.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
    callback(new Error "Errors encountered: #{data.toString()}")
  spawned.on 'exit', (code) =>
    return callback(new Error "Unexpected code #{code}") if code

    # TODO: spawn in the package.json directory
    options = _.clone(options)
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
    return installThenWriteBundle(filename, bundle, options, callback)

  return callback(new Error "Failed to generate bundle") unless bundle_code = mb.generateBundleCode(bundle, options)

  # make the destination directory
  resolved_filename = mb.resolveSafe(filename, options);
  try
    directory = path.dirname(resolved_filename)
    wrench.mkdirSyncRecursive(directory, 0o0777) unless existsSync(directory)
  catch e
    return callback(e) if e.code isnt 'EEXIST'

  bundle = "(function() {\n#{bundle_code}})(this);\n"

  # compress the bundle
  if options.compress or resolved_filename.endsWith('.min.js') or resolved_filename.endsWith('-min.js')
    ast = jsp.parse(bundle)
    ast = pro.ast_mangle(ast)
    ast = pro.ast_squeeze(ast)
    compressed_bundle = pro.gen_code(ast)

    # write compressed
    fs.writeFile(resolved_filename, compressed_bundle, 'utf8', -> callback())

  # write uncompressed
  else
    fs.writeFile(resolved_filename, bundle, 'utf8', -> callback())

mb.writeBundles = (config, options, callback) ->
  throw 'module-bundler: missing config filename or object' unless config
  throw 'module-bundler: missing options.cwd' unless (options and options.cwd)
  throw 'module-bundler: missing callback' unless callback

  # it is a filename so try to load it
  if _.isString(config)
    try config = require(mb.resolveSafe(config, options)) catch err then return callback(err)
    return callbacK(new Error "mbundle: failed to load #{config} configuration file. Does it exist?") if _.isString(config) # didn't load

  queue = new Queue(1)

  # npm packages
  installed_packages = []
  for filename, bundle of config
    do (filename, bundle) -> queue.defer (callback) ->
      return callback(new Error "mbundle: unexpected information for #{filename}") unless _.isObject(bundle)

      # install then bundle
      dir = path.dirname(filename)
      if not options.skip_install and (dir != options.cwd) and existsSync(path.join(dir, 'package.json')) and not (path in installed_packages)
        installed_packages.push(path)
        installThenWriteBundle(filename, bundle, options, callback)

      else
        mb.writeBundle(filename, bundle, options, callback)

  queue.await callback
