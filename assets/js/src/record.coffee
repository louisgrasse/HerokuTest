class Record
  constructor: (@attributes, @form) ->

  title: ->
    title_key = @form.record_title_key()
    if @attributes.form_values[title_key]
      if @attributes.form_values[title_key].other_values.length
        @attributes.form_values[title_key].other_values[0]
      else
        @attributes.form_values[title_key].choice_values[0]
    else
      '&nbsp;'

module.exports = Record