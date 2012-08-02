isString = (obj) ->
  return Object.prototype.toString.call(obj) == '[object String]'

contains = (array, value) ->
  (return true if test is value) for test in array
  return false

String::endsWith = (suffix) ->
  return @indexOf(suffix, @length - suffix.length) != -1

Array::contains = (check) ->
  for item in array
    return true if item is check
  return false

clone = (obj) ->
  result = {}
  (result[key] = value) for key, value of obj
  return result