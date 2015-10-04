
fp = require 'flipFP'
prim = require './primitives'

functions = [
  'enforceTypes'
  'enforceAllowed'
  'enforceRequired'
  'enforceUnique'
]

getMod = (name) -> require "./#{name}"
module.exports = enforceSchema = (req, doc) ->
  
  
  fp.pipe fp.map getMod, functions
