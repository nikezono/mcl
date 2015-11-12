_ = require 'underscore'

this.Edges = class Edges

  constructor: ->
    @edges = {}

  exists: (source, sink)->
    return @edges?[source]?[sink]? or @edges?[source]?[sink]?

  add: (source, sink)->
    if @exists(source, sink)
      @edges[source][sink] = (@edges[source][sink] + 1)|0
      @edges[sink][source] = (@edges[sink][source] + 1)|0
    else
      @set(source, sink, 1)

  set: (source, sink, cost)->
    if not source or not sink
      return throw Error("Invalid arguments. sourceId and sinkId is required.")

    if @exists(source, sink)
      @edges[source][sink] = cost|0
      @edges[sink][source] = cost|0
    else
      @edges[source] ||= {}
      @edges[source][sink] = cost|0
      @edges[sink] ||= {}
      @edges[sink][source] = cost|0

  getSinkNodes: (source)->
    if not @edges[source]
      return []
    else
      Object.keys(@edges[source])

  setEmptyValues: (selfLoop = true)->
    nodes = Object.keys(@edges)

    nodes.forEach (source)=>
      nodes.forEach (sink)=>
        if selfLoop and source is sink
          @edges[source][sink] ||= 1
        else
          @edges[source][sink] ||= 0

  getPendants: (nodes)->

    result = {}
    nodes.forEach (source)=>
      costed = []
      _.each @edges[source], (cost, sink)->
        return if nodes.indexOf(sink) is -1
        return if source is sink
        costed.push sink if cost > 0
      if costed.length is 1
        sink = costed[0]
        result[sink] ||= []
        result[sink].push source
    result

  generateMatrix: (nodes)->
    result = {}
    nodes.forEach (source)=>
      nodes.forEach (sink)=>
        result[source] ||= {}
        result[source][sink] = @edges[source][sink]
    result

  avarageDegrees: (nodes)->
    total = 0
    _.each @edges, (edges, source)->
      return if nodes.indexOf(source) is -1
      total += _.reduce edges, (memo, cost)->
        if cost > 0 then memo + 1 else memo
    total / Object.keys(@edges).length
