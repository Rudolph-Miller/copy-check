fs = require 'fs'
request = require 'request'
async = require 'async'
haml = require 'hamljs'
child = require 'child_process'
exec = child.exec
events = require 'events'

uuid = ->
  S4 = ->
    (((1+Math.random())*0x10000)|0).toString(16).substring(1)
  S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4()

exe = (text, callback) ->
  em = new events.EventEmitter
  id = uuid()
  uniquePath = "tmp/#{id}"
  fs.writeFileSync uniquePath, text, 'utf-8'
  cmd = "../src/main.exe #{uniquePath}"
  exec cmd, (err, stdout, stderr) ->
    if err
      console.log err
    else
      keyList = []
      arr = stdout.replace(/\s\(\)|\s$/g, '')
                  .split('\n')
                  .map((c) -> c.slice(1, -1).split(' '))
      async.forEach arr, (item) ->
        if item.length == 1
          keyList.push item[0]
      getIndexOfText arr, keyList, (indexList) ->
        counter = 0
        finish_counter = 0
        error_counter = 0
        results = {}

        inThread = (data) ->
          search data.key, (err, result) ->
            if err
              console.log err
              ++ error_counter
            else
              em.emit 'finish_thread', {result: result, index: data.index}

        threadFinish = (data) ->
          ++ finish_counter
          results[data.index] = data.result
          if finish_counter == counter
            em.emit 'end', results

        for item in arr
          ++ counter
          data =
            key: item.join()
            index: arr.indexOf item
          inThread data
        em.on 'finish_thread', threadFinish
        em.once 'end', (data) ->
          if (error_counter / counter) > 1/2
            console.log 'error happend'
            callbackData =
              type: 'error'
              query: counter
              length: text.length
              text: text
            callback callbackData
          else
            logData =
              type: 'success'
              date: (new Date()).toLocaleString()
              query: counter
              length: text.length
              text: text
            fs.appendFile 'log/bing.log', JSON.stringify(logData).toString() + '\n', (err) ->
              if err
                console.log err
            em.removeListener 'finish_thread', threadFinish
            callbackData = {}
            callbackData.keyList = keyList
            callbackData.query = counter
            callbackData.arr = []
            async.forEach [0..arr.length-1], (index) ->
              callbackData.arr.push({
                key: arr[index]
                index: indexList[index]
                value: data[index]})
            callback callbackData

search = (key, callback) ->
  credentials = JSON.parse (fs.readFileSync '.bing_credentials.json', 'utf-8')
  query = key.replace(/[\s\'\"]/g, '')
  uri = "https://api.datamarket.azure.com/Bing/SearchWeb/Web?"
          .concat "Query=\'\"#{query}\"\'"
          .concat "&$format=JSON"
          .concat "&Market=%27ja-JP%27"
          .concat "&$top=50"
  options =
    uri: uri
    auth:
      user: credentials.appId
      pass: credentials.appId
  request.post options, (err, res, body) ->
    if err
      console.log err
      callback(err)
    else
      try
        result = JSON.parse(body).d.results.length
      catch err
        console.log res
        callback err
      if result == 50
        result = 1000
      callback null, result / key.length
      
getIndexOfText = (arr, keyList, callback) ->
  result = []
  async.forEach arr, (item) ->
    index = arr.indexOf(item)
    ind = []
    async.forEach item, (str) ->
      ind.push keyList.indexOf str
    result[index] = ind
  callback result

formatting = (data, callback) ->
  if data.type == 'error'
    main data
  else
    query = data.counter
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
          type: 'success'
          result: result
          text:formatList.join('')
          rate: rate
          raw: query.text
          sum_len: sumLen
          true_len: trueLen
          query: query
        callback resultData

exports.exe = exe
exports.formatting = formatting
