layer_configs = require './layer_configs'
utils         = require '../utils'

createMap = (div_id, options) ->
  if options and 'layersControl' of options
    layersControl = options.layersControl
    delete options.layersControl
  map_options =
    center             : [0, 0]
    zoom               : 4
    attributionControl : false
  utils.extend map_options, options
  map = new L.Map div_id, map_options

  streets_layer   = new L.TileLayer layer_configs.mapbox_streets.url,   layer_configs.mapbox_streets.options
  map.addLayer streets_layer
  map

createGeoJSONLayer = (geojson_options) ->
  layer = new L.GeoJSON null, geojson_options
  layer

module.exports =
  createMap          : createMap
  createGeoJSONLayer : createGeoJSONLayer