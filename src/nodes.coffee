_ = require 'underscore'

this.Nodes = class Nodes

  constructor: ->
    @nodes = []

  set: (name)->
    if not name
      return throw Error("empty value is given.")
    if @exists(name)
      return throw new Error("#{name} is already created node.")
    @nodes.push name

  upsert: (name)->
    return name if @exists(name)
    @set(name)

  getIdByName: (name)->
    @nodes.indexOf(name)

  size: ->
    @nodes.length

  exists: (name)->
    _.contains(@nodes, name)

  all: ->
    return @nodes




