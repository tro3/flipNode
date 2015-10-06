types = require('./types')


isPrimitive = (val) ->
    return true if typeof val != 'object'
    return false if val instanceof Array
    return 'type' of val and !('schema' of val)


expand = (cfg, sch) ->
    sch = sch || {}
    for key, val of cfg
        if typeof val != 'object'
            sch[key] =
                type: val
        else if val instanceof Array
            if isPrimitive(val[0])
                if typeof val[0] != 'object'
                    sch[key] =
                        type: types.List
                        subtype:
                            type: val[0]
                else
                    sch[key] =
                        type: types.List
                        subtype: val[0]
            else                        
                sch[key] =
                    type: types.List
                    schema: val[0]
        else if !('type' of val)
            sch[key] =
                type: types.Doc
                schema: val
        else
            sch[key] = val
            
        if 'subtype' of sch[key] && typeof sch[key].subtype != 'object'
            sch[key].subtype = {type: sch[key].subtype}
        if 'schema' of sch[key]
            sch[key].schema = expand(sch[key].schema)
    sch._id =
        type: types.Id
    sch
    
    
module.exports = expand