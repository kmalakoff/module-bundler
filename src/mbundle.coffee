fs = require 'fs'
path = require 'path'
mb = require 'module-bundler'

mbundle = @mbundle = if (typeof(exports) != 'undefined') then exports else {}

# helpers
timeLog = (message) -> console.log("#{(new Date).toLocaleTimeString()} - #{message}")

mbundle.run = ->
  args = process.argv.slice(2);

  # missing arugments, exit
  (console.error('mbundle: missing filename'); process.exit(1)) unless args.length

  # bundle each config file
  for arg in args
    result = mb.writeBundlesSync(arg, {cwd: fs.realpathSync('.')})
    timeLog(if result then "mbundle: bundled #{arg}" else "mbundle: failed to bundle #{arg}")