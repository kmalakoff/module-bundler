isString = (obj) ->
  return Object.prototype.toString.call(obj) == '[object String]'

contains = (array, value) ->
  (return true if test is value) for test in array
  return false
