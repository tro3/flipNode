
x = module.exports


x.isDoc = isDoc = (sch) -> sch.type == types.Doc
x.isDocList = isDocList = (sch) -> sch.type == types.List and !('subtype' of sch)
x.isPrimList = isPrimList = (sch) -> sch.type == types.List and 'subtype' of sch
x.isPrimitive = isPrimitive = (sch) -> sch.type != types.Doc and sch.type != types.List
x.isReadOnly = isReadOnly = (sch) -> sch.type in types.ReadOnlyTypes
