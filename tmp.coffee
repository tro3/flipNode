R = require 'ramda'
p = console.log

pConcat = ->
    p = []
    for x in arguments
        x = String(x)
        if x.trim().length > 0
            p.push(x)
    p.join('.')
    
pConcat = ->
  R.join '.',
  R.filter ((x) -> x.length > 0),
  R.map (R.pipe(String, R.trim)), Array.prototype.slice.call(arguments)

p pConcat('a','b')





mapObjRec = R.curry (fn, val) ->
  fn2 = (val) ->
    if typeof val == 'object' then R.mapObj(fn2, val) else fn val
  return R.mapObj(fn2, val)
    

# (a -> a) -> {} -> {}
# or
# [(a -> a), ({} -> {}), ({} -> {})] -> {} -> {}
traverseObj = R.curry (fcns, val) ->
  if fcns instanceof Array
    fVal =     fcns[0] or (x) -> x
    fObjPost = fcns[1] or (x) -> x
    fObjPre =  fcns[2] or (x) -> x
  else
    fVal =     fcns
    fObjPost = (x) -> x
    fObjPre =  (x) -> x
  fLoop = (val) ->
    if typeof val == 'object' then fObjPost R.mapObj(fLoop, fObjPre val) else fVal val
  fObjPost R.mapObj(fLoop, fObjPre val)
    

omitEmpty = (obj) ->
  emptyKeys = R.filter ((k) -> obj[k] == undefined), R.keys obj
  R.omit emptyKeys, obj

addOne = (val) ->
  return val + 1 if typeof val == 'number'
  return if val == 'delete'
  return val

addOnes = traverseObj [addOne, omitEmpty]

p addOnes {
  a:1
  b: 'name'
  c: {
    a:1
    b:'name'
    c: 'delete'
  }
}
