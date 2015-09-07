
fp = require 'flipFP'
prim = require './primitives'
p = console.log



module.exports = enforceRequired = (endp) ->

  getValues = prim.getValues endp, fp.keys endp.paths.requireds
  
  filterNothings = fp.filter fp.isNothing fp.prop 'value'
  genErr = (value) -> {path: value.path, msg: "Value required at '#{value.path}'"}    
  findErrors = fp.map genErr, filterNothings getValues

  
  (inState, req) ->
    inState = prim.enforceState inState, req
    return {
      _state: true
      doc: inState.doc
      errs: fp.concat inState.errs, findErrors inState.doc
    }
