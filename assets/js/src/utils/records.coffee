xhr = require 'xhr'

getRecords = (cb) ->
  xhr_options =
    uri: '/api/records'
    json: true
  xhr_callback = (error, response, records) ->
    if error
      cb error, null
    else
      cb null, records
  xhr xhr_options, xhr_callback

updateRecord = (id, record, cb) ->
  delete record.uiDraggable
  data =
    record: record
  xhr_options =
    uri: "/api/records/#{id}"
    method: 'PUT'
    json: data
  xhr_callback = (error, response, record) ->
    if error
      cb error, null
    else
      cb null, record
  xhr xhr_options, xhr_callback

module.exports =
  getRecords:   getRecords
  updateRecord: updateRecord