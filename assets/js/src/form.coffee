xhr = require 'xhr'

class Form
  constructor: (form_json) ->
    @form_obj = form_json.form
    @init()

  init: ->

  name: ->
    @form_obj.name

  id: ->
    @form_obj.id

  record_title_key: ->
    @form_obj.record_title_key

  status_field: ->
    return @form_obj.status_field || null

  status_color: (value) ->
    if @status_field()
      for status in @status_field().choices
        if status.value is value or status.label is value
          return status.color

    return 'none'

module.exports = Form