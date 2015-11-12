debug = require('debug')('MCL')
_     = require 'underscore'

{ Nodes }  = require './nodes'
{ Edges }  = require './edges'

this.MCL = class MCL

  constructor: (option)->
    @undirectedMode = option?.undirectedMode || true # WIP
    @expanses = option?.expanses || 2
    @inflates = option?.inflates || 2
    @selfLoop = option?.selfLoop || true
    @pruning  = option?.pruning  || true

    @pruned = {}

    @nodes = new Nodes()
    @edges = new Edges()
    @workNodes = [] # temporary nodes for subgraph
    @graph = {} # random-walk propability matrix with label
    @result = {}
    @resultCache = {}

    @loopCount = 0
    @clustered = []
    @convergenced = false # is result homogeneous?

  initializeWorkVariables: ->
    @pruned = {}
    @workNodes = []
    @graph = {}
    @result = {}
    @resultCache = {}
    @loopCount = 0
    @clustered = []
    @convergenced = false

  addEdge: (source, sink)->
    @nodes.upsert(source)
    @nodes.upsert(sink)
    @edges.add source,sink

  setEdge: (source, sink, cost)->
    @nodes.upsert(source)
    @nodes.upsert(sink)
    @edges.set source, sink, cost

  # clustering graph network
  # @param node: segment target subgraph by single node
  clustering: (node)->
    if not _.isEmpty(node) and not @nodes.exists(node)
      throw new Error("there is no node named '#{node}'.")

    @initializeWorkVariables()

    @workNodes = if node then @edges.getSinkNodes(node) else @nodes.all()
    debug "all nodes: #{@workNodes.length}"
    if @pruning is true
      @pruned = @edges.getPendants(@workNodes)
      @workNodes = _.difference @workNodes, _.flatten(_.values(@pruned))

    debug "working nodes: #{@workNodes.length}"
    debug "avarage degrees: #{@edges.avarageDegrees(@workNodes)}"

    @edges.setEmptyValues(@selfLoop)
    @graph = @edges.generateMatrix(@workNodes)

    @normalize()

    while(@convergenced is not true)
      @expansion()
      @inflation()
      @checkConvergence()

    @toFixedValues()
    @divideCluster()

    @clustered

  normalize: ->
    totalCosts = {}
    _.each @graph, (edges, source)=>
      _.each edges, (cost, sink)=>

        # total cost of row
        totalCosts[sink] ||= _.reduce(_.values(@graph), (memo,elm)->
          memo+elm[sink]
        , 0)

        @result[source] ||= {}
        @result[source][sink] = (cost / totalCosts[sink]) || 0

  expansion: ->
    iterator = 0
    while(iterator < @expanses)
      result = {}
      @workNodes.forEach (row)=>
        result[row] ||= {}
        @workNodes.forEach (col)=>
          result[row][col] ||= 0
          @workNodes.forEach (i)=>
            #debug "plus", "#{row}-#{i}", "#{i}-#{col}","to #{row}-#{col}", result[row][col], (@result[row][i] * @result[i][col])
            result[row][col] += (@result[row][i] * @graph[i][col])

      @result = result
      iterator++

  inflation: ->
    iterator = 0
    while(iterator < @inflates)
      result = {}

      # POW
      @workNodes.forEach (row)=>
        result[row] ||= {}
        @workNodes.forEach (col)=>
          result[row][col] = (@result[row][col] * @result[row][col])

      # NORMALIZE
      totalCosts = {}
      _.each result, (edges, source)=>
        _.each edges, (cost, sink)=>

          totalCosts[sink] ||= _.reduce(_.values(result), (memo,edges)=>
            memo+edges[sink]
          ,0)

          result[source] ||= {}
          result[source][sink] = (cost / totalCosts[sink]) || 0

      @result = result
      iterator++

  checkConvergence: ->
    @loopCount++
    if _.isEqual @resultCache, @result
      @convergenced = true
    else
      @resultCache = @result

  toFixedValues: ->
    @workNodes.forEach (sink)=>
      @workNodes.forEach (source)=>
        @result[sink][source] = @result[sink][source].toFixed(1) * 1

  divideCluster: ->
    divided = []
    @workNodes.forEach (source)=>
      subResult = {}

      @workNodes.forEach (sink)=>
        parameter = @result[source][sink]
        if parameter > 0 and not _.contains(divided, sink)
          subResult[parameter] ||= []
          subResult[parameter].push sink
          divided.push sink

          # add pendant
          if @pruning and @pruned[sink]
            @pruned[sink].forEach (node)->
              subResult[parameter].push node
              divided.push node

      # divide atractors
      if not _.isEmpty(subResult)
        _.each subResult, (nodes, param)=>
          if not _.contains(@clustered, nodes)
            @clustered.push nodes

    _.difference(@workNodes, divided).forEach (node)=>
      @clustered.push [node]

    # add circular pendant(1-1 nodes)
    _.each @pruned, (sinks, source)=>
      if not _.contains divided, source
        cluster = [source].concat(sinks)
        @clustered.push cluster
        divided.push source
        sinks.forEach (sink)-> divided.push sink

  debug: ->
    debug "LOOP: #{@loopCount}"
    debug "NODES"
    debug @workNodes

    debug "GRAPH"
    debug @graph

    debug "PENDANTS"
    debug @pruned

    debug "RESULT"
    debug @result

    debug "CLUSTERED"
    debug @clustered


