schema = require('../schema')
types =  schema.types
List = types.List
Dict = types.Dict

p = console.log



descendApply = (data, fn, inds=[]) ->
    if data instanceof Array
        data.forEach (item, ind) ->
            descendApply(item, fn, inds.concat([ind]))
    else
        fn(data, inds)


extrapolatePath = (path, inds, schema) ->
    paths = []
    current = schema
    for attr in path.split('.')
        paths.push attr
        if current[attr].type == List
            paths.push inds[0]
            inds = inds.splice(1)
        current = current[attr].schema
    paths.join('.')
    


ex = module.exports

ex.required = (data, endp) ->
    errs = []
    for path, sch of endp.paths.requireds
        fn = (val, inds) ->
            if val == undefined || val == null || String(val).trim() == ''
                lpath = extrapolatePath(path, inds, endp.schema)
                errs.push {
                    path: lpath
                    msg: "Value required at #{lpath}"
                }
        descendApply(data.get(path), fn)
    errs