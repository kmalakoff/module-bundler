fs = require 'fs'
path = require 'path'
wrench = require 'wrench'
coffeescript = require 'coffee-script'

mb = @mb = if (typeof(exports) != 'undefined') then exports else {}
RESERVED = ['_publish', '_load', '_alias']

# add coffeescript compiling
require.extensions['.coffee'] ?= (module, filename) ->
  content = coffeescript.compile fs.readFileSync filename, 'utf8', {filename}
  module._compile content, filename

mb.writeBundleSync = (filename, config, options) ->
  throw 'module-bundler: missing output filename or object' unless filename
  throw 'module-bundler: missing config object' unless config
  throw 'module-bundler: missing options.cwd' unless (options and options.cwd)

  # make the destination directory
  try
    directory = path.dirname(filename)
    wrench.mkdirSyncRecursive(directory, 0o0777) unless path.existsSync(directory)
  catch e
    throw e if e.code isnt 'EEXIST'

  code = """
  (function() {\n
    #{mb.generateBundleCode(config, options)}
  })(this);
  """

  return fs.writeFileSync(filename, code, 'utf8')

mb.writeBundlesSync = (config, options) ->
  throw 'module-bundler: missing config filename or object' unless config
  throw 'module-bundler: missing options.cwd' unless (options and options.cwd)

  # it is a filename so try to load it
  if isString(config)
    try config = require(mb.resolveSafe(config, options)) catch e then (console.log(e.message); return)

  for filename, bundle_config of config
    mb.writeBundleSync(filename, bundle_config, options)