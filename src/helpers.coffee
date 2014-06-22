String::endsWith = (suffix) ->
  return @indexOf(suffix, @length - suffix.length) != -1
