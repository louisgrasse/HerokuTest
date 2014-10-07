async               = require 'async'
_                   = require 'underscore'

Form                = require './form'
Record              = require './record'

record_utils        = require './utils/records'
form_utils          = require './utils/forms'
member_utils        = require './utils/members'
map_utils           = require './utils/maps'


jQuery.fn.serializeObject = ->
  arrayData = @serializeArray()
  objectData = {}

  $.each arrayData, ->
    if @value?
      value = @value
    else
      value = ''

    if objectData[@name]?
      unless objectData[@name].push
        objectData[@name] = [objectData[@name]]

      objectData[@name].push value
    else
      objectData[@name] = value

  return objectData

class App
  init: ->
    @map = map_utils.createMap 'map-container'
    @queues = []
    @queueElements = []
    @recordElements = []
    # Marker styles
    @markerNormal =
      radius: 8
      color: "#fff"
      weight: 1
      opacity: 1
      fillOpacity: 0.7
      radius: 8
    @markerHighlight =
      color: "#000"
      weight: 3
      opacity: 1
      fillOpacity: 1
    @markerSuperHighlight =
      color: "#000"
      weight: 10
      opacity: 1
      fillOpacity: 1

    # Load data
    async.parallel {form: @getForm, records: @getRecords, dispatchers: @getDispatchers, technicians: @getTechnicians}, @setupCallback

  initEvents: ->
    # Setup UI events
    $('.queue .heading').on 'click', (event) =>
      @handleToggleQueue(event)
    $('.queue .heading .pin-toggle').on 'click', (event) =>
      @handleTogglePins(event)
    $('.queue').on 'mouseover', (event) =>
      @handleQueueMouseOver(event)
    $('.queue').on 'mouseout', (event) =>
      @handleQueueMouseOut(event)
    $('.records li').on 'mouseover', (event) =>
      @handleQueueRecordMouseOver(event)
    $('.records li span').on 'mouseover', (event) =>
      @handleQueueRecordMouseOver(event)
    $('.records li i').on 'mouseover', (event) =>
      @handleQueueRecordMouseOver(event)
    $('.records li').on 'mouseout', (event) =>
      @handleQueueRecordMouseOut(event)

  getForm: (callback) ->
    form_utils.getForm (error, form) ->
      if error
        callback error
      else
        callback null, form

  getRecords: (callback) ->
    record_utils.getRecords (error, records) ->
      if error
        callback error
      else
        callback null, records

  getDispatchers: (callback) ->
    member_utils.getDispatchers (error, memberships) ->
      if error
        callback error
      else
        callback null, memberships

  getTechnicians: (callback) ->
    member_utils.getTechnicians (error, memberships) ->
      if error
        callback error
      else
        callback null, memberships

  setupCallback: (error, results) =>
  # After retrieving data from Fulcrum, use the data to setup the application
    if error
      console.log error
      return

    form_json         = results.form
    records_json      = results.records
    technicians_json  = results.technicians
    dispatchers_json  = results.dispatchers

    @form = new Form form_json

    dispatcher       = dispatchers_json.memberships[0]
    technicians       = technicians_json.memberships

    # Need a queue for dispatcher records
    @dispatcher =
      user_id: dispatcher.user_id
      user: 'Dispatcher'

    # Add queue for dispatcher records
    @dispatcher_queue = @createQueue(@dispatcher)
    @queues.push(@dispatcher_queue) if @dispatcher_queue

    # Create a queue for each member with the technician role
    @createQueues(technicians)

    # Add records to queues
    @addRecordsToQueues(@queues, records_json.records)

    # For each queue, we need to be able to create a leaflet features layer
    # to display the records on the map
    # Create a feature collection for each queue
    @createQueuesFeatureCollections(@queues)
    @createQueuesFeatureCollectionLayers(@queues)

    @render()

  handleToggleQueue: (evt) ->
    # Show/hide Queue
    queue = $(evt.target).closest('.queue').find('.records')
    @toggleQueue(queue)
    evt.preventDefault()
    evt.stopPropagation()

  handleTogglePins: (evt) ->
    # Show/hide markers
    queue = $(evt.target).closest('.queue')
    @togglePins(queue)

    evt.preventDefault()
    evt.stopPropagation()

  handleQueueMouseOver: (evt) ->
  # Highlight markers associated with queue
    queue_dom = $(evt.target).closest('.queue')
    queue = @getQueueByUserId(queue_dom.data().user_id)
    queue.feature_layer.setStyle(@markerHighlight)

    evt.preventDefault()
    evt.stopPropagation()

  handleQueueMouseOut: (evt) ->
  # Remove highlight from markers associated with queue
    queue_dom = $(evt.target).closest('.queue')
    queue = @getQueueByUserId(queue_dom.data().user_id)
    queue.feature_layer.setStyle(@markerNormal)

    evt.preventDefault()
    evt.stopPropagation()

  handleQueueRecordMouseOver: (evt) ->
  # Highlight marker associated with record
    record_dom = $(evt.target).closest('li')
    record = record_dom.data()

    feature_collection =
      type         : 'FeatureCollection'
      features     : []

    feature = @createFeatureFromRecord(record)
    feature_collection.features.push(feature)

    markerStyle = @markerHighlight
    geojson_layer_options =
      style: (feature) =>
        fillColor: feature.color
      pointToLayer: (feature, latlng) =>
        L.circleMarker(latlng, markerStyle)
    @hightlight_layer = map_utils.createGeoJSONLayer geojson_layer_options
    @hightlight_layer.addData feature_collection

    @map.addLayer @hightlight_layer

    evt.preventDefault()
    evt.stopPropagation()

  handleQueueRecordMouseOut: (evt) ->
  # Remove highlight from marker associated with record
    @map.removeLayer @hightlight_layer

    evt.preventDefault()
    evt.stopPropagation()

  handleMarkerMouseOver: (marker) ->
  # Highlight record associated with marker
    record_id = marker.feature.id

    for record_dom in @recordElements
      if record_dom.data().id is record_id
        record_dom.addClass('record-highlight')

  handleMarkerMouseOut: (marker) ->
  # Remove highlight from record associated with marker
    record_id = marker.feature.id

    for record_dom in @recordElements
      if record_dom.data().id is record_id
        record_dom.removeClass('record-highlight')

  toggleQueues: (direction) ->
  # Show/hide queues
    for queue in @queueElements
      queue_records = $('.records', queue)
      @toggleQueue(queue_records)

  toggleQueue: (queue, direction) ->
  # Show/hide individual queue
    heading = queue.closest('.queue').find('.heading')
    queue = queue.closest('.queue').find('.records')
    if $('.queue-toggle', heading).hasClass('fa-angle-up')
      dir = 'hide'
    else
      dir = 'show'

    if direction
      @toggleRecords(queue, direction)
      $('.queue-toggle', heading).toggleClass('fa-angle-up fa-angle-down') unless dir is direction
    else
      @toggleRecords(queue, dir)
      $('.queue-toggle', heading).toggleClass('fa-angle-up fa-angle-down')

  toggleRecords: (queue, direction) ->
  # Show/hide records
    if direction is 'hide'
      queue.hide()
    else
      queue.show()

  togglePins: (queue_dom) ->
  # Show/hide markers
    queue = queue_dom.data()
    $('.pin-toggle', queue_dom).toggleClass('fa-check-square-o fa-square-o')

    if $('.pin-toggle', queue_dom).hasClass('fa-check-square-o')
      #add layer
      @addQueueFeatureCollectionLayerToMap(queue)
    else
      #remove layer
      @removeQueueFeatureCollectionLayerFromMap(queue)

  assignRecord: (evt, recordItem) ->
  # Assign the record based on the queue it is dragged into
    if $(evt.target).length
      drop = $(evt.target)
      queue_dom = drop.closest('.queue')
      new_queue = @getQueueByUserId(queue_dom.data().user_id)
      assigned_to_id = new_queue.user_id || null
      records = queue_dom.find('.records ul')
      record = recordItem.data()
      old_record = _.clone(record)
      old_queue = @getQueueByUserId(record.assigned_to_id)

      if (record.assigned_to_id || null) isnt assigned_to_id
        record.assigned_to_id = assigned_to_id
        record_utils.updateRecord record.id, record, (error, record) =>
          if error
            recordItem.draggable({ revert: true })
            alert "The appointment was not able to be updated."
          else
            recordItem.data(record)
            recordItem.fadeOut () ->
              recordItem.appendTo(records).fadeIn () ->
                recordItem

            @removeRecordFromQueue(old_queue, old_record)
            @addRecordToQueue(new_queue, record)

            # Handle the markers on the map
            old_layer_on = old_queue.feature_layer_on
            new_layer_on = new_queue.feature_layer_on

            if old_layer_on
              @removeQueueFeatureCollectionLayerFromMap(old_queue)
            if new_layer_on
              @removeQueueFeatureCollectionLayerFromMap(new_queue)

            @createQueuesFeatureCollections([old_queue, new_queue])
            @createQueuesFeatureCollectionLayers([old_queue, new_queue])

            if old_layer_on
              @addQueueFeatureCollectionLayerToMap(old_queue)
            if new_layer_on
              @addQueueFeatureCollectionLayerToMap(new_queue)

  render: () ->
    # Create DOM elements for queues
    # Fill queue DOM elements with records
    @renderQueues(@queues)

    # Set the bounds of the map
    feature_collection =
      type         : 'FeatureCollection'
      features     : []

    # Get all of the features across queues to establish map bounds
    for queue in @queues
      feature_collection.features.push(queue.feature_collection.features) if queue.feature_collection.features.length
    feature_collection.features = _.flatten(feature_collection.features)
    if feature_collection.features.length
      feature_layer = new L.GeoJSON feature_collection
      @map.fitBounds(feature_layer)

    # Setup drag and drop
    $('.draggable li').draggable(
      revert: "invalid"
      helper: "clone"
      cursor: "move"
    )
    $( ".droppable" ).droppable(
      accept: ".draggable li"
      activeClass: "ui-state-highlight"
      drop: (event, ui) =>
        @assignRecord(event, ui.draggable)
    )

    # Setup default queue view
    queue_dom = @getQueueDOMElementByUserId(@dispatcher.user_id)
    if queue_dom
      @toggleQueue(queue_dom)
      @togglePins(queue_dom)

    # Setup various UI events
    @initEvents()
    @

  renderQueues: (queues) ->
   # Loop through queues, create DOM elements
    for queue in queues
      queue_dom = @renderQueue(queue)
      if queue_dom
        queue_dom.data(queue)
        $('#queues').append(queue_dom)
        $('.records', queue_dom).hide()

        @queueElements.push(queue_dom)

  renderQueue: (queue) ->
  # Create DOM element for queue
    recs = []
    html = $("")
    if queue
      recs = @renderQueueRecords(queue)
      html = $("<div class=\"queue\">
        <div class=\"heading droppable\">
          <i class=\"fa fa-square-o pin-toggle\" />
          <span>#{queue.label}</span>
          <i class=\"fa fa-angle-down queue-toggle pull-right\" />
        </div>
        <div class=\"records\">
          <ul class=\"draggable droppable\"></ul>
        </div>
      </div>")

    for rec in recs
      $("ul", html).append(rec)
    html

  renderQueueRecords: (queue) ->
  # Loop through records, create DOM elements
    recs = []
    records = queue.records || []
    for record in records
      record = new Record record, @form
      record_dom = @renderRecord(record)
      @recordElements.push(record_dom)
      recs.push(record_dom)
    recs

  renderRecord: (record) ->
  # Create DOM element for record
    color = @form.status_color(record.attributes.status)
    rec = $("<li><i class=\"fa fa-circle\" style=\"color:#{color}\" />
      <span>#{record.title()}</span></li>").data(record.attributes)

  createQueues: (members) ->
  # Loop through technicians, create a queue for each technician
    for member in members
      queue = @createQueue(member)
      @queues.push(queue)

  createQueue: (member) ->
  # Create a queue for a technician
    queue =
      user_id: member.user_id
      label: member.user
      records: []
      feature_collection:
        type         : 'FeatureCollection'
        features     : []
      feature_layer: null
      feature_layer_on: false

    queue

  addRecordsToQueues: (queues, records) ->
  # Add records to queue
    for record in records
      queue = _.find queues, (q) ->
        q.user_id is record.assigned_to_id
      if queue
        @addRecordToQueue(queue, record)

  addRecordToQueue: (queue, record) ->
  # Add a record to a queue
    queue.records.push(record)
    queue

  removeRecordFromQueue: (queue, record) ->
  # Remove a record from a queue
    queue.records = _.filter queue.records, (rec) ->
      rec.id != record.id
    queue

  createQueuesFeatureCollections: (queues) ->
  # Create a collection of map features for each queue
    for queue in queues
      @createQueueFeatureCollection(queue)

  createQueueFeatureCollection: (queue) ->
  # Create a collection of map features for a queue
    @resetQueueFeatureCollection(queue)
    for record in queue.records
      feature = @createFeatureFromRecord(record)
      @addFeatureToQueueFeatures(queue, feature) if feature

  resetQueueFeatureCollection: (queue) ->
  # Clear a queue's feature collection
    queue.feature_collection.features = []

  createFeatureFromRecord: (record) ->
  # Create a map feature form a record
    color = @form.status_color(record.status)
    geometry =
      type        : 'Point'
      coordinates : [record.longitude, record.latitude]
    feature =
      type       : 'Feature'
      id         : record.id
      properties : record.form_values
      geometry   : geometry
      color      : color
    feature

  addFeatureToQueueFeatures: (queue, feature) ->
  # Add feature to a queue's features
    if queue and queue.feature_collection and queue.feature_collection.features and feature
      queue.feature_collection.features.push(feature)

  createQueuesFeatureCollectionLayers: (queues) ->
  # Create layers for queue feature collections
    for queue in queues
      layer = @createQueueFeatureCollectionLayer(queue)
      @addQueueFeatureCollectionLayer(queue, layer) if layer

  createQueueFeatureCollectionLayer: (queue) ->
  # Create a layer for a queue's feature collection
    markerStyle = @markerNormal
    geojson_layer_options =
      style: (feature) =>
        fillColor: feature.color
      pointToLayer: (feature, latlng) =>
        L.circleMarker(latlng, markerStyle)
      onEachFeature: (feature, marker) =>
        marker.on 'mouseover', =>
          @handleMarkerMouseOver marker
        marker.on 'mouseout', =>
          @handleMarkerMouseOut marker
    feature_layer = map_utils.createGeoJSONLayer geojson_layer_options
    feature_layer.addData queue.feature_collection

    feature_layer

  addQueueFeatureCollectionLayer: (queue, layer) ->
  # Set a queue's feature collection layer
    queue.feature_layer = layer if queue

  removeQueueFeatureCollectionLayer: (queue) ->
  # Remove a queue's feature collection layer
    queue.feature_layer = null if queue

  addQueueFeatureCollectionLayerToMap: (queue) ->
  # Add a queue's feature collection layer to the map
    queue = @getQueueByUserId(queue.user_id)
    @map.addLayer queue.feature_layer
    queue.feature_layer_on = true

  removeQueueFeatureCollectionLayerFromMap: (queue) ->
  # Remove a queue's feature collection layer form the map
    queue = @getQueueByUserId(queue.user_id)
    @map.removeLayer queue.feature_layer
    queue.feature_layer_on = false

  getQueueByUserId: (user_id) ->
  # Find a queue for a given user
    queue = _.find @queues, (q) ->
      q.user_id is user_id
    queue || null

  getQueueDOMElementByUserId: (user_id) ->
  # Find a queue's DOM element for a given user
    queue = _.find @queueElements, (q) ->
      q.data().user_id is user_id
    queue || null

app = new App()
app.init()