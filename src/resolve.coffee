runInExecDir = (fn, cwd) ->
  if cwd
    original_dirname = fs.realpathSync('.')
    process.chdir(cwd)
    result = fn()
    process.chdir(original_dirname)
  else
    return fn()

mb.pathNormalizeSafe = (target, options={}) ->
  cwd = path.normalize(options.cwd) if options.cwd
  return target if (target.substr(0, process.env.HOME.length) is process.env.HOME)      # already resolved
  return target if cwd and (target.substr(0, cwd.length) is cwd)                        # already resolved

  runInExecDir((->
    try (target = path.normalize(target)) catch e
  ), cwd)
  return target

mb.requireResolveSafe = (target, options={}) ->
  return target if (target.substr(0, process.env.HOME.length) is process.env.HOME)      # already resolved

  # always in the scope of the node process
  target = target
  try (target = require.resolve(target)) catch e
  return target

# options:
#   cwd - current working directory for file system resolve
#   skip_require - skip using require
#   must_exist - the target must exist (for example, for output files, we need to resolve their location, but they do not need to exist)
mb.resolveSafe = (target, options={}) ->
  cwd = path.normalize(options.cwd) if options.cwd
  is_file = target.search(/^file:\/\//) >= 0
  target = target.replace(/^file:\/\//, '') if is_file
  target = mb.requireResolveSafe(target, options) unless (options.skip_require or is_file)
  return target if (target.substr(0, process.env.HOME.length) is process.env.HOME)      # already resolved
  return target if cwd and (target.substr(0, cwd.length) is cwd)                        # already resolved

  if target[0] is '.'
    # check that next characters are . or /, but not characters indicating a hidden directory
    (next_char = char; break if char isnt '.' and char isnt '/') for char in target
    if next_char is '.' or '/'
      raw_target = path.join((if cwd then cwd else cwd), target)
    else
      raw_target = path.join(cwd, target)
  else if target[0] is '~'
    raw_target = target.replace(/^~/, process.env.HOME)
  else if cwd
    raw_target = path.join(cwd, target)
  else
    raw_target = target

  path_to_target = path.normalize(raw_target)
  return '' if options.must_exist and not existsSync(path_to_target)
  return path_to_target
