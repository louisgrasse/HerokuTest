xhr = require 'xhr'

getTechnicians = (cb) ->
  xhr_options =
    uri: '/api/technicians'
    json: true
  xhr_callback = (error, response, memberships) ->
    if error
      cb error, null
    else
      cb null, memberships
  xhr xhr_options, xhr_callback

getDispatchers = (cb) ->
  xhr_options =
    uri: '/api/dispatchers'
    json: true
  xhr_callback = (error, response, memberships) ->
    if error
      cb error, null
    else
      cb null, memberships
  xhr xhr_options, xhr_callback

module.exports =
  getTechnicians: getTechnicians
  getDispatchers: getDispatchers