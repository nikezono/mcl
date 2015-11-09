debug = require('debug')('MCL')
_     = require 'underscore'

this.MCL = class MCL

  constructor: (option)->
    @undirectedMode = option?.undirectedMode || true # WIP
    @expanses = option?.expanses || 2
    @inflates = option?.inflates || 2
    @selfLoop = option?.selfLoop || true

    @nodes = [] # store all node's key
    @edges = {} # store all edges with weight

    @workNodes = [] # target segmented nodes of graph
    @workEdges = {} # target segmented Edges of graph

    @graph = {} # random-walk propability matrix with label
    @result = {}
    @resultCache = {}

    @loopCount = 0
    @clustered = []
    @convergenced = false # is result homogeneous?

  addEdge: (node, targetNode)->
    @nodes.push node if not _.contains(@nodes, node)
    @nodes.push targetNode if not _.contains(@nodes, targetNode)
    @edges[node] ||= {}
    @edges[targetNode] ||= {}
    @edges[node][targetNode]++
    @edges[targetNode][node]++

  setEdge: (node, targetNode, cost)->
    @nodes.push node if not _.contains(@nodes, node)
    @nodes.push targetNode if not _.contains(@nodes, targetNode)
    @edges[node] ||= {}
    @edges[targetNode] ||= {}
    @edges[targetNode][node] = cost
    @edges[node][targetNode] = cost


  # clustering graph network
  # @param node: segment target subgraph by single node
  clustering: (node)->
    if not _.isEmpty(node) and not  _.contains(@nodes, node)
      throw new Error("there is no node named '#{node}'.")

    @setTargetSegment(node)
    @generateMatrix()
    @normalize()

    while(@convergenced is not true)
      @expansion()
      @inflation()
      @checkConvergence()

    @toFixedValues()
    @divideCluster()
    @debug()
    @clustered

  setTargetSegment: (node)->
    if node
      nodes = Object.keys(@edges[node])
      nodes = nodes.filter (el)-> el isnt node # @todo change by selfLoop flag
      edges = {}
      nodes.forEach (subNode)=>
        nodes.forEach (targetNode)=>
          edges[subNode] ||= {}
          edges[subNode][targetNode] = @edges[subNode][targetNode] || 0
    else
      nodes = @nodes
      edges = @edges

    @workNodes = nodes
    @workEdges = edges

  generateMatrix: ->

    @workNodes.forEach (node)=>
      @workNodes.forEach (targetNode)=>
        @workEdges[targetNode] ||= {}
        if not _.has(@workEdges[node], targetNode)
          @workEdges[node][targetNode] = 0
        if @selfLoop is true and node is targetNode
          @workEdges[node][targetNode] = 1

  normalize: ->
    _.each @workEdges, (subEdges, node)=>
      _.each subEdges, (cost, targetNode)=>

        # total cost of row
        totalCost = _.reduce(_.values(@workEdges), (memo,elm)->
          memo+elm[targetNode]
        ,0)

        @graph[node] ||= {}
        @graph[node][targetNode] = (cost / totalCost) || 0
    @result = @graph

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
      _.each result, (edges, node)=>
        _.each edges, (cost, targetNode)=>

          totalCost = _.reduce(_.values(result), (memo,edges)=>
            memo+edges[targetNode]
          ,0)

          result[node] ||= {}
          result[node][targetNode] = (cost / totalCost) || 0

      @result = result
      iterator++

  checkConvergence: ->
    @loopCount++
    debug "#{@loopCount}th loop"
    if _.isEqual @resultCache, @result
      @convergenced = true
    else
      @resultCache = @result

  toFixedValues: ->
    @workNodes.forEach (node)=>
      @workNodes.forEach (targetNode)=>
        @result[node][targetNode] = @result[node][targetNode].toFixed(1) * 1


  divideCluster: ->
    divided = []
    @workNodes.forEach (node)=>
      subResult = []
      @workNodes.forEach (targetNode)=>
        if @result[node][targetNode] > 0
          subResult.push targetNode
          divided.push targetNode

      # divide atractors
      if not _.isEmpty(subResult) and not _.contains(@clustered, subResult)
        @clustered.push subResult

    _.difference(@workNodes, divided).forEach (node)=>
      @clustered.push [node]


  debug: ->
    debug "NODES"
    debug @workNodes

    debug "EDGES"
    debug @workEdges

    debug "MATRIX"
    debug @workNodes.map (node)=>
      @workNodes.map (targetNode)=>
        @workEdges[node][targetNode]

    debug "NORMALIZED GRAPH"
    debug @graph

    debug "RESULT"
    debug @result

    debug "CLUSTERED"
    debug @clustered


