schema = require('../schema')
types =  schema.types
List = types.List
Dict = types.Dict
ReadOnly = types.ReadOnly

p = console.log


evaluate = (val, path, key, type, errs) ->
    try
        return type(val)
    catch
        errs.push({path:pConcat(path,key), msg:"Could not convert '#{pConcat(path,key)}' value of '#{val}'"})
        return null


pConcat = ->
    p = []
    for x in arguments
        x = String(x)
        if x.trim().length > 0
            p.push(x)
    p.join('.')
    

module.exports = incoming = (data, sch, path='') ->
    errs = []
    for key, val of data
        if key not of sch
            delete data[key]
        else if sch[key].type == Dict
            errs = errs.concat(incoming(val, sch[key].schema, pConcat(path,key)))
        else if sch[key].type == List
            if 'subtype' of sch[key]
                newval = []
                val.forEach (x, ind) ->
                    newval.push(evaluate(x, pConcat(path,key), ind, sch[key].subtype.type, errs))                     
                data[key] = newval
            else
                val.forEach (x, ind) ->
                    errs = errs.concat(incoming(x, sch[key].schema, pConcat(path,key,ind)))
        else
            newval = evaluate(val, path, key, sch[key].type, errs) 
            if newval == types.ReadOnly
                delete data[key]
            else
                data[key] = newval
    errs