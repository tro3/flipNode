fp = require 'flipFP'

prim = require './enforceSchema/primitives'
schema = require '../schema'
types =  schema.types

p = console.log
x = module.exports



processVal = (sch, o, n) ->
  if      prim.isDoc(sch) then     processDoc(sch.schema, o, n)
  else if prim.isDocList(sch) then processList(sch.schema, o, n)
  else if prim.isReadOnly(sch) then return o || null
  else if prim.isPrimList(sch)
    return o if n == undefined and o != undefined
    return [] if n == undefined and o == undefined
    return n
  else
    return o if n == undefined and o != undefined
    return null if n == undefined and o == undefined
    return n

processList = (sch, o, n) ->
  o = [] if o not instanceof Array
  n = [] if n not instanceof Array
  r = []
  for doc in n
    r.push processDoc sch, prim.get(o, doc._id), doc
  r
  
processDoc = (sch, o, n) ->
  o = {} if typeof o != 'object'
  n = {} if typeof n != 'object'
  r = {}
  for key in fp.keys sch
    r[key] = processVal sch[key], o[key], n[key]
  r
    

module.exports = (endp, old, new_) -> processDoc endp.schema, old, new_