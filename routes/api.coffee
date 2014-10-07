express = require 'express'
request = require 'request'

Fulcrum = require 'fulcrum-app'
Memberships = require '../assets/js/src/memberships'

constants = require '../constants'
utils     = require '../utils'

fulcrum = new Fulcrum({api_key: constants.api_key, url: constants.api_url})
router  = express.Router()

memberships = new Memberships()

router.get '/technicians', (req, res) ->
  callback = (error, memberships) ->
    if error
      console.log "Error: #{error}"
      res.send 'Error'
      return
    res.json memberships
  params =
    role_id: constants.technician_role_id
  utils.extend params, req.query
  memberships.search params, callback

router.get '/dispatchers', (req, res) ->
  callback = (error, memberships) ->
    if error
      console.log "Error: #{error}"
      res.send 'Error'
      return
    res.json memberships
  params =
    role_id: constants.dispatcher_role_id
  utils.extend params, req.query
  memberships.search params, callback

router.get '/records', (req, res) ->
  callback = (error, records) ->
    if error
      console.log "Error: #{error}"
      res.send 'Error'
      return
    res.json records
  params =
    form_id: constants.form_id
  utils.extend params, req.query
  fulcrum.records.search params, callback

router.put '/records/:record_id', (req, res) ->
  callback = (error, record) ->
    if error
      console.log "Error: #{error}"
      res.send String(error), 500
      return
    res.json record.record
  fulcrum.records.update req.params.record_id, req.body, callback

router.get '/form', (req, res) ->
  callback = (error, form) ->
    if error
      console.log "Error: #{error}"
      res.send 'Error'
      return
    res.json form
  fulcrum.forms.find constants.form_id, callback

module.exports = router