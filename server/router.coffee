routes = (handle, path, res, query) ->
  if typeof handle[path] == 'function'
    handle[path] res, query
  else
    'No handler'

exports.routes = routes
