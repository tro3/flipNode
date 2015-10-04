
fp = require 'flipFP'
prim = require './primitives'
p = console.log



module.exports = enforceAllowed = (env) ->

  endp = env.endpoint
  root = env.doc

  checkNotAllowed = (value) ->
    alloweds =  if typeof value.sch.allowed == 'function'
                  value.sch.allowed(prim.getParent(endp, value.path, root), root, env)
                else
                  value.sch.allowed
    alloweds = fp.concat(alloweds, [null, undefined]) if !value.sch.envuired
    return value.value not in alloweds

  getValues = prim.getValues endp, fp.keys endp.paths.alloweds  
  findErrors = (values) -> fp.map genErr, fp.filter checkNotAllowed, values
  genErr = (value) -> {path: value.path, msg: "Value '#{value.value}' at '#{value.path}' not allowed"}

  env.errs = fp.concat env.errs, findErrors(getValues root) 
  return env