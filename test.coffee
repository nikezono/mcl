{ MCL } = require './src/mcl'
assert = require 'assert'

describe "mcl", ->

  context "with regular case", ->

    context "without option", ->
      it "returns clustered node array", ->
        mcl = new MCL
        setTemplateEdges(mcl)
        clustered = mcl.clustering()

        assert.deepEqual clustered, [
          [ 'alice', 'bob', 'dave', 'carol' ],
          [ 'silva', 'kun', 'nasri', 'toure', 'hart']
        ]

      it "doesn't put the same node in 2 clusters", ->
        mcl = new MCL
        setTemplateEdges(mcl)
        clustered = mcl.clustering()

        for cluster, i in clustered
          for otherCluster, j in clustered when i < j
            for c in cluster
              assert c not in otherCluster

      it "doesn't put the same node in 2 clusters when using data that exposes this bug", ->
        mcl = new MCL
        setProblematicEdges(mcl)
        clustered = mcl.clustering()

        for cluster, i in clustered
          for otherCluster, j in clustered when i < j
            for c in cluster
              assert c not in otherCluster, "#{c} is in [#{cluster}] and [#{otherCluster}]"


      context "with two nodes", ->
        it "returns clustered node array", ->
          mcl = new MCL
          mcl.setEdge 'alice', 'bob', 3
          clustered = mcl.clustering()
          assert.deepEqual clustered, [['bob', 'alice']]

    context "with subgraph option", ->
      it "returns segmented and clustered node array", ->
        mcl = new MCL
        setTemplateEdges(mcl)
        clustered = mcl.clustering('alice')
        assert.deepEqual clustered, [ [ 'hart' ], [ 'carol', 'bob' ]]

      it "can also returns whole clustered node array", ->
        mcl = new MCL
        setTemplateEdges(mcl)
        clustered = mcl.clustering('alice')
        assert.deepEqual clustered, [ [ 'hart' ], [ 'carol', 'bob' ]]

        clustered = mcl.clustering()
        assert.deepEqual clustered, [
          [ 'alice', 'bob', 'dave', 'carol' ],
          [ 'silva', 'kun', 'nasri', 'toure', 'hart']
        ]

setTemplateEdges = (mcl)->
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

setProblematicEdges = (mcl) ->
  mcl.setEdge 'alice', 'bob',  1
  mcl.setEdge 'alice', 'carol',  3
