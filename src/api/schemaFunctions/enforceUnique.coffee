
fp = require 'flipFP'
prim = require './primitives'
p = console.log


module.exports = enforceUnique = (endp) ->
  
  req = null

  hasDuplicate = (value) ->
    query = fp.zipObj [value.path],[value.value]
    req.cache.findOne(req.collection, query).then (doc) -> doc != null

  getValues = prim.getValues endp, fp.keys endp.paths.uniques
  genErr = (value) -> {path: value.path, msg: "Value required at '#{value.path}'"}    
  findErrors = fp.map genErr, fp.qFilter hasDuplicate, getValues
  
  (inState, inReq) ->
    inState = prim.enforceState inState, inReq
    req = inState.req
    return findErrors(inState.doc).then (errs) -> {
      _state: true
      doc: inState.doc
      req: inState.req
      errs: fp.concat inState.errs, errs
    }
