
fp = require 'flipFP'
prim = require './primitives'
p = console.log


module.exports = enforceUnique = (env) ->
  
  endp = env.endpoint
  
  hasDuplicate = (value) ->
    query = fp.zipObj [value.path],[value.value]
    env.cache.findOne(env.collection, query).then (doc) -> doc != null

  getValues = prim.getValues endp, fp.keys endp.paths.uniques
  genErr = (value) -> {path: value.path, msg: "Value '#{value.value}' at '#{value.path}' is not unique"}    
  findErrors = fp.map genErr, fp.qFilter hasDuplicate, getValues
  
  return findErrors(env.doc).then (errs) ->
    env.errs = fp.concat env.errs, errs
    return env
