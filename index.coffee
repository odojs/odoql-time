moment = require 'timespanner'
helpers = require 'odoql-utils/helpers'

module.exports =
  unary:
    time: (exe, params) ->
      helpers.unary exe, params, (source) ->
        moment.spanner source
  # params:
  #   delta: 