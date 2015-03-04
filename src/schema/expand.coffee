types = require('./types')


isPrimitive = (val) ->
    return true if typeof val != 'object'
    return false if val instanceof Array
    return 'type' of val and !('schema' of val)


expand = (cfg) ->
    sch = {}
    for key, val of cfg
        if typeof val != 'object'
            sch[key] =
                type: val
        else if val instanceof Array
            if isPrimitive(val[0])
                sch[key] =
                    type: types.List
                    subtype: val[0]
            else                        
                sch[key] =
                    type: types.List
                    schema: val[0]
        else if !('type' of val)
            sch[key] =
                type: types.Dict
                schema: val
        else
            sch[key] = val
            
        if 'schema' of sch[key]
            sch[key].schema = expand(sch[key].schema)
            
    sch
    
    
module.exports = expand