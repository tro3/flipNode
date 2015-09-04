types = require('./types')
p = console.log

# Will collect all sch paths in which fn({type:String, required:true}) == true
recurseCollect = (sch, fn, path='') ->
    paths = []
    sep = if path == '' then '' else '.'
    for key, val of sch
        paths.push("#{path}#{sep}#{key}") if typeof val != 'function' && fn(val)
        if 'schema' of val
            paths = paths.concat(recurseCollect(val.schema, fn, "#{path}#{sep}#{key}"))
    paths


x = module.exports

x.all = (sch) ->
    recurseCollect(sch, () -> true)

x.primitives = (sch) ->
    recurseCollect(sch, (x) -> !('schema' of x))

x.withTrueProp = (sch, prop) ->
    fn = (x) -> (prop of x && x[prop]) || (x.type == types.List && ('subtype' of x) && prop of x.subtype && x.subtype[prop])
    recurseCollect(sch, fn)

x.withProp = (sch, prop) ->
    fn = (x) -> prop of x || (x.type == types.List && ('subtype' of x) && prop of x.subtype)
    recurseCollect(sch, fn)

x.ofType = (sch, type) ->
    fn = (x) -> x.type == type || (x.type == types.List && ('subtype' of x) && x.subtype.type == type)
    recurseCollect(sch, fn)
    
x.ifTrue = (sch, fn) ->
    recurseCollect(sch, fn)
