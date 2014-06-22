_ = require 'underscore'

mb.generateLibraryCode = ->
  return """
    var root = this;
    var root_require = root.require;
    var root_require_define = root_require ? root.require.define : null;
    var root_require_resolve = root_require ? root.require.resolve : null;

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
      }
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
    if (root_require) {
      // copy all additional properties
      for (var key in root_require)
        root.require[key] = root_require[key];
    }
    root.require.resolve = mb.require_resolve;\n
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
  entries = [entries] if _.isString(entries)
  for module_name in entries
    code += "root.require('#{module_name}');\n"
  return code

mb.generateModuleCode = (module_name, filename, options) ->
  throw "module name cannot be a reservered word: #{module_name}" if module_name in RESERVED

  pathed_file = mb.resolveSafe(filename, options)
  try
    file_contents = fs.readFileSync(pathed_file, 'utf8')
  catch e
    console.log "Couldn't bundle '#{filename}'. Does it exist?"
    return

  return "\nmb.require_define({'#{module_name}': function(exports, require, module) {\n\n#{file_contents}\n}});\n"

mb.generateBundleCode = (bundle, options) ->
  code = mb.generateLibraryCode()

  success = true
  for key, value of bundle
    continue if key in RESERVED # skip special commands
    module_code = mb.generateModuleCode(key, value, options) # add the modules
    if module_code then (code += module_code) else (success = false)

  code += mb.generateAliasCode(bundle._alias) if bundle.hasOwnProperty('_alias') # create aliases
  code += mb.generatePublishCode(bundle._publish) if bundle.hasOwnProperty('_publish') # publish symbols (for example, some libraries assume dependencies can be found on window)
  code += mb.generateLoadCode(bundle._load) if bundle.hasOwnProperty('_load') # require now so they are loaded automatically when this bundle is loaded

  if success then return code else return