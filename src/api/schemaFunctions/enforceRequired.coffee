
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
    
