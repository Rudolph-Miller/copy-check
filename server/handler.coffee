haml = require 'hamljs'
coffee = require 'coffee-script'
fs = require 'fs'
cc = require './copy_check'
async = require 'async'

index = (res, query) ->
  res.writeHead '200', 'Content-Type': 'text/html'
  contentsData =
    title: 'copy check'
  indexData =
    title: 'こぴぺちぇっかー'
  fs.readFile 'view/index.haml', 'utf-8', (err, data) ->
    if err
      console.log err
    else
      contentsData.contents = haml.render data, locals: indexData
      fs.readFile 'view/layout.haml', 'utf-8', (err, data) ->
        res.write haml.render data, locals: contentsData
        res.end()

check = (res, query) ->
  main = (result) ->
    if result.type == 'error'
      errorData =
        query: result.query
        length: result.length
        text: result.text
      res.write 'おっこちた...かも....'
      res.end()
    else
      checkData =
        result: result.text
        rate: Math.round(result.rate*10) / 10
        raw: result.raw
        sum_len: result.sum_len
        true_len: result.true_len
      fs.readFile 'view/result.haml', 'utf-8', (err, data) ->
        if err
          console.log err
        else
          res.write haml.render data, locals: checkData
          res.end()

  if query.item != 'check'
    res.end()
  else
    res.writeHead '200', 'Conten-Type': 'text/html'
    cc.exe query.text, (data) -> cc.formatting data, main


api = (res, query) ->
  main = (result) ->
    if result.type == 'error'
      res.writeHead '500', 'Content-Type': 'application/json'
      errorData =
        text: result.text
        length: result.length
      res.write JSON.stringify errorData
      res.end()
    else
      res.writeHead '200', 'Content-Type': 'application/json'
      resultData =
        text: result.raw
        result:result.result
        html: result.text
        rate: Math.round(result.rate*10) / 10
        words: result.sum_len
        query: result.query
      res.write JSON.stringify resultData
      res.end()

    cc.exe query.text, (data) -> cc.formatting data, main

booing = (res, query) ->
  if query.item != 'booing'
    res.writeHead '403', 'Content-Type': 'text/plain'
    res.end 'forbidden action'
  else
    res.writeHead '200', 'Content-Type': 'text/plain'
    res.end()
    logData =
      text: query.text
      date: (new Date()).toLocaleString()
    fs.appendFile 'log/log', JSON.stringify(logData).toString()+'\n', 'utf-8', (err) ->
      if err
        console.log err

backToIndex = (res) ->
  indexData =
    title: 'こぴぺちぇっかー'
  res.writeHead 'Coview/ntent-Type': 'text/html'
  fs.readFile 'view/index.haml', 'utf-8', (err, data) ->
    if err
      console.log err
    else
      res.write haml.render data, locals: indexData
      res.end()

controller = (res) ->
  fs.readFile 'controller.coffee', 'utf-8', (err, data) ->
    if err
      console.log err
    else
      res.writeHead 200, "Content-Type": "text/javascript"
      res.end coffee.compile data

loading = (res) ->
  res.writeHead '200', 'Content-Type': 'image/gif'
  fs.readFile 'view/loading.gif', (err, data) ->
    if err
      console.log err
    else
      res.end data, 'binary'
      fs.writeFile 'sample.gif', data, (err) ->
        if err
          console.log err
  
exports.index = index
exports.check = check
exports.api = api
exports.booing = booing
exports.backToIndex = backToIndex
exports.controller = controller
exports.loading = loading
