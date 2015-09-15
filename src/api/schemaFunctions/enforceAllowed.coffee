
fp = require 'flipFP'
prim = require './primitives'
p = console.log



module.exports = enforceAllowed = (endp) ->

  root = null
  req = null


  checkNotAllowed = (value) ->
    alloweds =  if typeof value.sch.allowed == 'function'
                  value.sch.allowed(prim.getParent(endp, value.path, root), root, req)
                else
                  value.sch.allowed
    alloweds = fp.concat(alloweds, [null, undefined]) if !value.sch.required
    return value.value not in alloweds


  getValues = prim.getValues endp, fp.keys endp.paths.alloweds  
  findErrors = (values) -> fp.map genErr, fp.filter checkNotAllowed, values
  genErr = (value) -> {path: value.path, msg: "Value '#{value.value}' at '#{value.path}' not allowed"}
  
  
  (inState, inReq) ->
    inState = prim.enforceState inState, inReq
    root = inState.doc
    req = inState.req
    return {
      _state: true
      doc: inState.doc
      req: inState.req
      errs: fp.concat inState.errs, findErrors(getValues inState.doc) 
    }