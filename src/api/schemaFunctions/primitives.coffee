mpath = require 'mpath'
fp = require 'flipFP'

schema = require '../schema'
types =  schema.types

getPaths = require '../schema/paths'

p = console.log
x = module.exports


x.isDoc = (sch) -> sch.type == types.Doc
x.isDocList = (sch) -> sch.type == types.List and !('subtype' of sch)
x.isPrimList = (sch) -> sch.type == types.List and 'subtype' of sch
x.isPrimitive = (sch) -> sch.type != types.Doc and sch.type != types.List
x.isReadOnly = (sch) -> sch.type in types.ReadOnlyTypes

x.join = (p1, p2) -> "#{p1}#{if p1.length then '.' else ''}#{p2}"
