
fp = require 'flipFP'
prim = require './primitives'
p = console.log


nonIdKeys = (sch) ->
  fp.filter ( (k) -> !(prim.isReadOnly sch[k]) && k != '_id'), fp.keys sch

      
# {endpoint} -> ({sch}, {}..., String -> a) -> ({}... -> {})
module.exports = enforceTypes = (env) ->
  
  endp = env.endpoint
  errs = env.errs
    
  loopFn = (sch, val, path) ->
    switch
      when prim.isDoc(sch)       then processDoc(sch.schema, val, path)
      when prim.isDocList(sch)   then processDocList(sch.schema, val, path)
      when prim.isPrimList(sch)  then processPrimList(sch.subtype.type, val, path)
      when prim.isPrimitive(sch) then processPrim(sch.type, val, path)

  processDoc = (sch, obj, path) ->
    fn = (key) -> loopFn sch[key], obj[key], prim.join(path, key)
    fp.zipKeys fn, (fp.keys sch)

  processDocList = (sch, lst, path) ->
    fn = (doc, i) -> processDoc sch, doc, prim.join(path, i)
    fp.mapIndex fn, lst

  processPrimList = (type, lst, path) ->
    fn = (val, i) -> processPrim type, val, prim.join(path, i)
    fp.mapIndex fn, lst

  processPrim = (type, val, path) ->
    return null if val == null
    try
        return type(val)
    catch
        errs.push({path:path, msg:"Could not convert '#{path}' value of '#{val}'"})
        return null

  env.doc = processDoc endp.schema, env.doc, ''
  env
    