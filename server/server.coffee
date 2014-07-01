http = require 'http'
url = require 'url'
qs = require 'querystring'

start = (port, routes, handle) ->
  onRequest = (req, res) ->
    res.setHeader 'Access-Control-Allow-Origin', '*:*'
    url_parts = url.parse req.url
    path = url_parts.pathname
    if req.method == 'POST'
      body = ''
      req.on 'data', (data) -> body += data
      req.on 'end', ->
        query = qs.parse body
        routes handle, path, res, query
    else
      query = qs.parse url_parts.query
      routes handle, path, res, query

  server = http.createServer(onRequest)
  server.listen(port)

exports.start = start
