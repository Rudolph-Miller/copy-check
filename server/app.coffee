server = require './server'
router = require './router'
handler = require './handler'

port = 8888
handle =
  '/': handler.index
  '/check': handler.check
  '/controller': handler.controller
  '/back_to_index': handler.backToIndex
  '/booing': handler.booing
  '/loading': handler.loading

server.start port, router.routes, handle
