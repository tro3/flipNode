
fp = require 'flipFP'
prim = require './primitives'
p = console.log



module.exports = enforceRequired = (endp) ->

  checkIfNothing = fp.isNothing fp.prop 'value'

  getValues = prim.getValues endp, fp.keys endp.paths.requireds  
  genErr = (value) -> {path: value.path, msg: "Value required at '#{value.path}'"}    
  findErrors = fp.map genErr, fp.filter checkIfNothing, getValues

  
  (inState, req) ->
    inState = prim.enforceState inState, req
    return {
      _state: true
      doc: inState.doc
      req: inState.req
      errs: fp.concat inState.errs, findErrors inState.doc
    }
