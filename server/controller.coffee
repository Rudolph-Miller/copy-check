$("#check").click ->
  postData =
    text: $("#check_text_area").val()
    item: 'check'
  $.ajax
    url: 'check'
    type: 'post'
    data: postData
    success: (result) -> $("#contents").html(result)
    error: (error) -> console.log error

$(".back_to_index").click ->
  $.ajax
    url: 'back_to_index'
    type: 'post'
    success: (result) -> $("#contents").html(result)
    error: (error) -> console.log error

$("#booing").click ->
  postData =
    result: $("#check_result").html()
    text: $("#raw_text").html()
    item: 'booing'
  $.ajax
    url: 'booing'
    type: 'post'
    data: postData
    success:(success) -> alert 'ふーん'
    error: (error) -> alert '・・・'
