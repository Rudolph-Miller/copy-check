haml = require 'hamljs'
coffee = require 'coffee-script'
fs = require 'fs'
copy_check = require './copy_check'
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
  res.writeHead '200', 'Conten-Type': 'text/html'
  main = (result) ->
    if query.item != 'check'
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

  formatting = (data) ->
    result = []
    async.forEach [0..data.keyList.length-1], (ind) ->
      result[ind] = {}
      result[ind].key = data.keyList[ind]
    async.forEach [0..data.arr.length-1], (index) ->
      val = data.arr[index].value
      if val != 0 && val <= 1.5
        async.forEach data.arr[index].index, (i) ->
          if i >= 0
            result[i].tf = true

    trueLen = 0
    sumLen = 0
    (result.map (obj) ->if obj.tf then obj.key.length else 0)
      .reduce (prev, cur) -> trueLen += cur
    (result.map (obj) -> obj.key.length)
      .reduce (prev, cur) -> sumLen += cur
    rate = (trueLen / sumLen) * 100

    fs.readFile 'view/format.haml', 'utf-8', (err, data) ->
      if err
        console.log err
      else
        formatList = result.map (obj) ->
          if obj.tf == undefined
            obj.tf = false
          (haml.render data, locals: obj).slice(1)
        resultData =
          text:formatList.join('')
          rate: rate
          raw: query.text
          sum_len: sumLen
          true_len: trueLen
        main resultData

  copy_check.exe query.text, formatting

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
exports.booing = booing
exports.backToIndex = backToIndex
exports.controller = controller
exports.loading = loading
