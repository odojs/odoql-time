moment = require 'timespanner'
helpers = require 'odoql-exe/helpers'

decaycurve = (x) -> (x - 1) * (x - 1)

module.exports =
  unary:
    time_coerce: (exe, params) ->
      helpers.unary exe, params, (source) ->
        moment.spanner source
  params:
    time: (exe, params) ->
      helpers.params exe, params, (params, source) ->
        moment source, params
    time_format: (exe, params) ->
      helpers.params exe, params, (params, source) ->
        source.format params
    time_delta: (exe, params) ->
      helpers.params exe, params, (params, source) ->
        source.spanner params
    time_nudge: (exe, params) ->
      getlookback = exe.build params.__p.lookback
      getrange = exe.build params.__p.range
      getvalues = exe.build params.__p.values
      getdata = exe.build params.__p.data
      getsource = exe.build params.__s
      (cb) ->
        getlookback (err, lookback) ->
          return cb err if err?
          getrange (err, range) ->
            return cb err if err?
            getvalues (err, values) ->
              return cb err if err?
              getdata (err, data) ->
                return cb err if err?
                getsource (err, source) ->
                  return cb err if err?
                  return cb null, source if data.length is 0
                  lastobstime = data[0].time
                  for d in data
                    lastobstime = d.time if lastobstime.isBefore d.time
                  fcpoint = null
                  for d in source
                    if d.time.isSame(lastobstime) or d.time.isAfter(lastobstime)
                      fcpoint = d
                      break
                  return cb null, source if !fcpoint?
                  lookbackuntil = lastobstime.clone().spanner lookback
                  obs = data.filter (d) ->
                    return yes if d.time.isSame lastobstime
                    d.time.isBefore(lastobstime) and d.time.isAfter(lookbackuntil)
                  return cb null, source if obs.length is 0
                  averages = {}
                  for v in values
                    averages[v] = 0
                    for d in obs
                      averages[v] += d.value
                    averages[v] /= obs.length
                  rangeuntil = lastobstime.clone().spanner range
                  rangems = rangeuntil.diff lastobstime
                  deltas = {}
                  for v in values
                    deltas[v] = averages[v] - fcpoint[v]
                  for d in source
                    if d.time.isSame(lastobstime) or (d.time.isBefore(rangeuntil) and d.time.isAfter(lastobstime))
                      x = d.time.diff lastobstime
                      for v in values
                        d[v] += deltas[v] * decaycurve x / rangems
                  cb null, source
    time_fill: (exe, params) ->
      helpers.params exe, params, (params, source) ->
        return params if source.length is 0
        return source if params.length is 0

        results = []
        si = 0
        sj = 0
        while yes
          while si < source.length and sj < params.length and params[sj].time.isBefore source[si].time
            results.push params[sj]
            sj++
          while si < source.length and sj < params.length and source[si].time.isBefore params[sj].time
            results.push source[si]
            si++
          break if si is source.length and sj is params.length
          if si is source.length
            while sj < params.length
              results.push params[sj]
              sj++
            break
          if sj is params.length
            while si < source.length
              results.push source[si]
              si++
            break
          if source[si].time.isSame params[sj].time
            merged = {}
            for prop, value of source[si]
              merged[prop] = value
            for prop, value of params[sj]
              merged[prop] = value if !merged[prop]?
            results.push merged
            si++
            sj++
            continue
          console.log "Shouldn't get here"
          break

        results
