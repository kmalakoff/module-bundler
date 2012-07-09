mb.generateLibraryCode = ->
  return """
    var root = this;
    var root_require = require;
    var root_require_define = require.define;
    var root_require_resolve = require.resolve;

    /*
    Define module-bundler require functions
    */
    var mb = (typeof(exports) !== 'undefined') ? exports : {};
    mb.modules = {};
    mb.require = function(module_name) {
      if (!mb.modules.hasOwnProperty(module_name)) {
        if (root_require) {
          return root_require.apply(this, arguments);
        }
        throw "Cannot find module '" + module_name + "'";
      }
      if (!mb.modules[module_name].exports) {
        mb.modules[module_name].exports = {};
        mb.modules[module_name].loader.call(root, mb.modules[module_name].exports, mb.require, mb.modules[module_name]);
      }
      return mb.modules[module_name].exports;
    };
    mb.require_define = function(obj) {
      for (var module_name in obj) {
        mb.modules[module_name] = {loader: obj[module_name]};
      };
    };
    mb.require_alias = function(alias_name, module_name) {
      mb.modules[alias_name] = {exports: root.require(module_name)};
    };
    mb.require_resolve = function(module_name) {
      if (!mb.modules[module_name]) {
        if (root_require_resolve) {
          return root_require_resolve.apply(this, arguments);
        }
        throw "Cannot find module '" + module_name + "'"
      }
      return module_name;
    };

    // overwrite the root implementation
    root.require = mb.require;
    for (var key in root_require)
      root.require[key] = root_require[key];  // copy all additional properties
    root.require.resolve = mb.root_require_resolve;\n
  """

mb.generateAliasCode = (entries) ->
  code = "\n"
  for alias_name, module_name of entries
    code += "mb.require_alias('#{alias_name}', '#{module_name}');\n"
  return code

mb.generatePublishCode = (entries) ->
  code = "\n"
  for symbol, module_name of entries
    code += "root['#{symbol}'] = root.require('#{module_name}');\n"
  return code

mb.generateLoadCode = (entries) ->
  code = "\n"
  entries = [entries] if isString(entries)
  for module_name in entries
    code += "root.require('#{module_name}');\n"
  return code

mb.generateModuleCode = (module_name, filename, options) ->
  throw "module name cannot be a reservered word: #{module_name}" if contains(RESERVED, module_name)

  pathed_file = mb.resolveSafe(filename, options)
  try
    file_contents = fs.readFileSync(pathed_file, 'utf8')
  catch e
    console.log "Couldn't bundle #{filename}. Does it exist?"
    throw "Couldn't bundle #{filename}. Does it exist?"

  return """
    mb.require_define({
      '#{module_name}': function(exports, require, module) {\n#{file_contents}\n}
    });\n
    """

mb.generateBundleCode = (config, options) ->
  code = mb.generateLibraryCode()

  for key, value of config
    continue if contains(RESERVED, key) # skip special commands
    code += mb.generateModuleCode(key, value, options) # add the modules

  code += mb.generateAliasCode(config._alias) if config.hasOwnProperty('_alias') # create aliases
  code += mb.generatePublishCode(config._publish) if config.hasOwnProperty('_publish') # publish symbols (for example, some libraries assume dependencies can be found on window)
  code += mb.generateLoadCode(config._load) if config.hasOwnProperty('_load') # require now so they are loaded automatically when this bundle is loaded

  return code