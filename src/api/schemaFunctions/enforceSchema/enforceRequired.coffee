
fp = require 'flipFP'
prim = require './primitives'
p = console.log



module.exports = enforceRequired = (env) ->
  
  endp = env.endpoint

  checkIfNothing = fp.isNothing fp.prop 'value'

  getValues = prim.getValues endp, fp.keys endp.paths.requireds  
  genErr = (value) -> {path: value.path, msg: "Value required at '#{value.path}'"}    
  findErrors = fp.map genErr, fp.filter checkIfNothing, getValues

  env.errs = fp.concat env.errs, findErrors env.doc
  env