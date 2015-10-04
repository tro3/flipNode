
fp = require 'flipFP'
prim = require './primitives'
p = console.log

functions = [
  'enforceTypes'
  'enforceAllowed'
  'enforceRequired'
  'enforceUnique'
]


module.exports = enforceSchema = (req, doc) ->

  result = {req:req, doc:doc, errs:[]}

  endp = req.endpoint
  getMod = (name) -> require("./#{name}")(endp)
  a = fp.pipe fp.map getMod, functions
  p a
  p a.length
  p a(result)
    
  (fp.pipe (fp.map getMod, functions))(result)