q = require('q')
mpath = require('mpath')

schema = require('../schema')
types =  schema.types
List = types.List
Dict = types.Dict

qForItems = require('./common').qForItems

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
                    msg: "Value required at '#{lpath}'"
                }
        descendApply(mpath.get(path, data), fn)
    errs
    
    
ex.allowed = (data, endp, req) ->
    errs = []
    for path, sch of endp.paths.alloweds
        allowFcn = if typeof sch.allowed == 'function' then sch.allowed else () -> sch.allowed
        parentPath = path.split('.')[...-1].join('.')
        attr = path.split('.').slice(-1)
        fn = (val, inds) ->
            allowVals = allowFcn(val, data, req)
            if !('required' of sch) or sch.required = false
                allowVals.push(null)
                allowVals.push(undefined)
            if allowVals.indexOf(val[attr]) == -1
                lpath = extrapolatePath(path, inds, endp.schema)
                errs.push {
                    path: lpath
                    msg: "Value '#{val[attr]}' at '#{lpath}' not allowed"
                }
        descendApply(mpath.get(parentPath, data) || data, fn)
    errs
    

ex.unique = (data, endp, req) ->
    errs = []
    qs = []
    qForItems endp.paths.uniques, (path, sch) ->
        query = {}
        query[path] = mpath.get(path, data)
        req.cache.findOne(req.collection, query)
        .then (doc) ->
            if doc != null
                errs.push {
                    path: path
                    msg: "Value '#{mpath.get(path, data)}' at '#{path}' is not unique"
                }            
    .then -> errs
    .catch (err) ->
        errs.push(err)
        errs
