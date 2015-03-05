

# Will collect all sch paths in which fn({type:String, required:true}) == true
recurseCollect = (sch, fn, path='') ->
    paths = []
    sep = if path == '' then '' else '.'
    for key, val of sch
        paths.push("#{path}#{sep}#{key}") if typeof val != 'function' && fn(val)
        if 'schema' of val
            paths = paths.concat(recurseCollect(val.schema, fn, "#{path}#{sep}#{key}"))
    paths



module.exports.all = (sch) ->
    recurseCollect(sch, () -> true)

module.exports.primitives = (sch) ->
    recurseCollect(sch, (x) -> !('schema' of x))
    
module.exports.withTrueProp = (sch, prop) ->
    fn = (x) -> prop of x && x[prop]
    recurseCollect(sch, fn)
    
    