debug = require('debug')('MCL')
_     = require 'underscore'

this.MCL = class MCL

  constructor: (option)->
    @undirectedMode = option?.undirectedMode || true # WIP
    @expanses = option?.expanses || 2
    @inflates = option?.inflates || 2
    @selfLoop = option?.selfLoop || false # WIP

    @nodes = [] # store all node's key
    @edges = {} # store all edges with weight
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


  getCluster: ->
    @clustered

  generateMatrix: ->
    @nodes.forEach (node)=>
      @nodes.forEach (targetNode)=>
        @edges[targetNode] ||= {}
        if not _.has(@edges[node], targetNode)
          @edges[node][targetNode] = 0

  normalize: (target)->
    _.each @edges, (edges, node)=>
      _.each edges, (cost, targetNode)=>

        # total cost of row
        totalCost = _.reduce(_.values(@edges), (memo,edges)=>
          memo+edges[targetNode]
        ,0)

        @graph[node] ||= {}
        @graph[node][targetNode] = (cost / totalCost) || 0
    @result = @graph

  expansion: ->
    iterator = 0
    while(iterator < @expanses)
      result = {}
      @nodes.forEach (row)=>
        result[row] ||= {}
        @nodes.forEach (col)=>
          result[row][col] ||= 0
          @nodes.forEach (i)=>
            #debug "plus", "#{row}-#{i}", "#{i}-#{col}","to #{row}-#{col}", result[row][col], (@result[row][i] * @result[i][col])
            result[row][col] += (@result[row][i] * @graph[i][col])

      @result = result
      iterator++

  inflation: ->
    iterator = 0
    while(iterator < @inflates)
      result = {}

      # POW
      @nodes.forEach (row)=>
        result[row] ||= {}
        @nodes.forEach (col)=>
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
    @nodes.forEach (node)=>
      @nodes.forEach (targetNode)=>
        @result[node][targetNode] = @result[node][targetNode].toFixed(1) * 1


  divideCluster: ->
    @nodes.forEach (node)=>
      subResult = []
      @nodes.forEach (targetNode)=>
        if @result[node][targetNode] > 0
          subResult.push targetNode

      # divide atractors
      if not _.isEmpty(subResult) and not _.contains(@clustered, subResult)
        @clustered.push subResult


  debug: ->
    debug "MATRIX"
    debug @nodes.map (node)=>
      @nodes.map (targetNode)=>
        @edges[node][targetNode]

    debug "NORMALIZED GRAPH"
    debug @graph

    debug "RESULT"
    debug @result

    debug "CLUSTERED"
    debug @clustered


