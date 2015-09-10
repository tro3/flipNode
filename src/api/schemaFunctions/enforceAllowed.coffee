
fp = require 'flipFP'
prim = require './primitives'
p = console.log



module.exports = enforceAllowed = (endp) ->

  root = null
  req = null


  parentPath = (path) -> path.split('.')[...-1].join('.')
  getParent = (path) -> prim.extractFromPath(endp)(parentPath path)(root)[0].value
    
  checkNotAllowed = (value) ->
    alloweds =  if typeof value.sch.allowed == 'function'
                  value.sch.allowed(getParent(value.path), root, req)
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

#
#
#schema = require '../schema'
#types =  schema.types
#endp =
#  paths:
#    alloweds:
#      'a':
#        type: types.Integer
#        allowed: [1,2]
#      'e.f':
#        type: types.Integer
#        allowed: [1,2]
#
#  schema:
#    a:
#      type: types.Integer
#      allowed: [1,2]
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
#          allowed: [1,2]
#          
#
#val =
#  a: 1
#  b:
#    c: null
#  d:[3,4]
#  e:[
#    {f:2}
#    {f:6}
#  ]
#
#parentPath = (path) -> (path.split('.')[0...-1]).join '.'
#getParent = fp.pipe parentPath, prim.extractFromPath(endp)
#parentExtractors = fp.map getParent, fp.keys endp.paths.alloweds
#getParents = fp.flatten fp.callAll parentExtractors
#
#
#p enforceAllowed(endp)(val)