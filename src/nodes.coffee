_ = require 'underscore'

this.Nodes = class Nodes

  constructor: ->
    @nodes = {}
    @id    = 0

  set: (name)->
    if not name
      return throw Error("empty value is given.")
    if @exists(name)
      return throw new Error("#{name} is already created node.")
    @id += 1
    @nodes[name] = @id

  upsert: (name)->
    return name if @exists(name)
    @set(name)

  size: ->
    Object.keys(@nodes).length

  exists: (name)->
    @nodes[name]?

  all: ->
    return Object.keys(@nodes)




