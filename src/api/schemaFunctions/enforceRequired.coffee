
fp = require 'flipFP'
prim = require './primitives'
p = console.log



module.exports = enforceRequired = (endp) ->

  # List of extraction fcns by path
  extractors = fp.map prim.extractFromPath(endp), fp.keys endp.paths.requireds
  
  getValues = fp.flatten fp.callAll extractors
  filterNothings = fp.filter fp.isNothing fp.prop 'value'
  getPaths = fp.map fp.prop 'path'
  genErr = (path) -> {path: path, msg: "Value required at '#{path}'"}
  
  (inState) ->
    inState = {doc:inState, errs:[]} if '_state' not of inState
    errs = filterNothings getValues inState.doc
    return {
      _state: true
      doc: inState.doc
      errs: fp.concat inState.errs, fp.map genErr, getPaths errs
    }
    
#
#
#schema = require '../schema'
#types =  schema.types
#endp =
#  paths:
#    requireds:
#      'a': 1
#      'b.c':1
#      'e.f':1
#  schema:
#    a:
#      type: types.Integer
#    b:
#      type: types.Doc
#      schema:
#        c:
#          type: types.Integer
#    d:
#      type: types.List
#      subtype: types.Integer
#    e:
#      type: types.List
#      schema:
#        f:
#          type: types.Integer
#          
#
#val =
#  a: 1
#  b:
#    c: null
#  d:[3,4]
#  e:[
#    {f:5}
#    {f:6}
#  ]
#
#
#extractors = fp.map prim.extractFromPath(endp), fp.keys endp.paths.requireds
#getValues = fp.flatten fp.callAll extractors
#filterNothings = fp.filter fp.isNothing fp.prop 'value'
#getPaths = fp.map fp.prop 'path'
#genMsg = (path) -> {path: path, msg: "Value required at '#{path}'"}
#
#
#errs = filterNothings getValues val
#p errs
#
#
#f = enforceRequired(endp)
#
#p f(val)
