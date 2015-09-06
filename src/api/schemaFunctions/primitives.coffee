mpath = require 'mpath'
fp = require 'flipFP'

schema = require '../schema'
types =  schema.types

getPaths = require '../schema/paths'

p = console.log
x = module.exports


x.isDoc = isDoc = (sch) -> sch.type == types.Doc
x.isDocList = isDocList = (sch) -> sch.type == types.List and !('subtype' of sch)
x.isPrimList = isPrimList = (sch) -> sch.type == types.List and 'subtype' of sch
x.isPrimitive = isPrimitive = (sch) -> sch.type != types.Doc and sch.type != types.List
x.isReadOnly = isReadOnly = (sch) -> sch.type in types.ReadOnlyTypes

x.join = join = (p1, p2) -> "#{p1}#{if p1.length then '.' else ''}#{p2}"


x.extractFromPath = (endp) ->
  
  processDoc = (stack, sch, val, path) ->
    [key, stack] = fp.splitHead stack
    sch = sch[key]
    path = join path, key
    return [{path:path, sch:sch, value:undefined}] if key not of val
    val = val[key]
    return [{path: path, sch:sch, value: val}] if stack.length == 0
    
    switch
      when isDoc(sch)       then processDoc(stack, sch.schema, val, path)
      when isDocList(sch)   then processDocList(stack, sch.schema, val, path)
      when isPrimList(sch)  then [{path: join(path, stack[0]), sch:sch, value: val[stack[0]]}]

  processDocList = (stack, sch, lst, path) ->
    if stack[0] of sch
      fn = (doc, i) -> processDoc stack, sch, doc, join(path, i)
      fp.flatten fp.mapIndex fn, lst
    else
      [key, stack] = fp.splitHead stack
      return [{path: join(path, key), sch:sch, value: lst[key]}] if stack.length == 0
      processDoc(stack, sch, lst[key], join(path, key))

  (path) ->
    (doc) ->
      return [{path:'', sch:{type:types.Doc, schema:endp.schema}, value:doc}] if path == ''
      stack = path.split('.')
      processDoc(stack, endp.schema, doc, '')
      
#
#endp =
#  schema:
#    a:
#      type: types.Integer
#    b:
#      type: types.Doc
#      schema:
#        c:
#          type: types.Integer
#    d:
#      type: types.List
#      subtype: types.Integer
#    e:
#      type: types.List
#      schema:
#        f:
#          type: types.Integer
#val =
#  a: 1
#  b:
#    c: 2
#  d:[3,4]
#  e:[
#    {f:5}
#    {f:6}
#  ]
#      
#p x.extractFromPath(endp)('a')(val)
#p x.extractFromPath(endp)('b.c')(val)
#p x.extractFromPath(endp)('d.1')(val)
#p x.extractFromPath(endp)('e.f')(val)
#p x.extractFromPath(endp)('e.1.f')(val)
#     
