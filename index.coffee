moment = require 'timespanner'
helpers = require 'odoql-exe/helpers'

module.exports =
  unary:
    asTime: (exe, params) ->
      helpers.unary exe, params, (source) ->
        moment.spanner source
  params:
    formatTime: (exe, params) ->
      helpers.params exe, params, (params, source) ->
        source.format params
    deltaTime: (exe, params) ->
      helpers.params exe, params, (params, source) ->
        source.spanner params

