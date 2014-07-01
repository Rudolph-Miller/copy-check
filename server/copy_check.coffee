fs = require 'fs'
request = require 'request'
async = require 'async'
child = require 'child_process'
exec = child.exec
events = require 'events'
em = new events.EventEmitter

uuid = ->
  S4 = ->
    (((1+Math.random())*0x10000)|0).toString(16).substring(1)
  S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4()

exe = (text, callback) ->
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
        results = {}
        for item in arr
          ++ counter
          data =
            key: item.join()
            index: arr.indexOf item
          inThread data
        em.on 'finish_thread', (data) ->
          ++ finish_counter
          results[data.index] = data.result
          if finish_counter == counter
            em.emit 'end', results
        em.on 'end', (data) ->
          callbackData = {}
          callbackData.keyList = keyList
          callbackData.arr = []
          async.forEach [0..arr.length-1], (index) ->
            callbackData.arr.push({
              key: arr[index]
              index: indexList[index]
              value: data[index]})
          callback callbackData

search = (key, callback) ->
  credentials = JSON.parse (fs.readFileSync '.bing_credentials.json', 'utf-8')
  uri = "https://api.datamarket.azure.com/Bing/SearchWeb/Web?"
          .concat "Query=\'\"#{key}\"\'"
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
      result = JSON.parse(body).d.results.length
      if result == 50
        result = 1000
      callback null, result / key.length
      
inThread = (data) ->
  search data.key, (err, result) ->
    if err
      console.log err
    else
      em.emit 'finish_thread', {result: result, index: data.index}

getIndexOfText = (arr, keyList, callback) ->
  result = []
  async.forEach arr, (item) ->
    index = arr.indexOf(item)
    ind = []
    async.forEach item, (str) ->
      ind.push keyList.indexOf str
    result[index] = ind
  callback result

exports.exe = exe
