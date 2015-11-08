{ MCL } = require './mcl'
assert = require 'assert'

describe "mcl", ->

  context "with regular case", ->
    mcl = new MCL

    mcl.setEdge 'alice', 'bob', 1
    mcl.setEdge 'alice', 'carol', 3
    mcl.setEdge 'bob', 'dave', 2
    mcl.setEdge 'carol', 'bob', 5
    mcl.setEdge 'bob', 'alice', 3

    mcl.setEdge 'silva', 'nasri', 10
    mcl.setEdge 'toure', 'silva', 7
    mcl.setEdge 'nasri', 'toure', 4
    mcl.setEdge 'kun', 'silva', 3
    mcl.setEdge 'hart', 'toure', 5
    mcl.setEdge 'hart', 'alice', 1

    it "returns clustered node array", ->

      clustered = mcl.clustering()

      assert.deepEqual clustered, [
        [ 'alice', 'bob', 'carol', 'dave' ],
        [ 'silva', 'nasri', 'toure', 'kun', 'hart']
      ]

