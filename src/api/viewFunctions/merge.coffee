schema = require('../schema')
prototype = schema.prototype
List = schema.types.List
Doc = schema.types.Doc
p = console.log



collectIds = (list) ->
    lookup = {}
    for obj in list
        lookup[obj._id] = obj
    lookup


module.exports = merge = (old, new_, schema) ->
    result = {}
    for key, val of schema
        if typeof val != 'function'
            
            if val.type == Doc
                o = if key of old then old[key] else prototype(val.schema)
                n = if key of new_ then new_[key] else {}
                if typeof o == 'object' && typeof n == 'object'
                    result[key] = merge(o, n, val.schema)
                else
                    result[key] = n
                
            else if val.type == List
                if 'subtype' of val                                  # Primitive list
                    if key of new_
                        result[key] = new_[key]
                    else if key of old
                        result[key] = old[key]
                    else
                        result[key] = []
                            
                else if key of new_                                  # Modified object list
                        o = if key of old && old[key] instanceof Array then old[key] else []
                        lookup = collectIds(o)
                        result[key] = []
                        for n in new_[key]
                            o = if n._id of lookup then lookup[n._id] else prototype(val.schema)
                            result[key].push merge(o, n, val.schema)
                            
                else if !(key of old)                                # Schema change
                    result[key] = []

            else                                                     # Primitive
                if key of new_
                    result[key] = new_[key]
                else if key of old
                    result[key] = old[key]
                else
                    result[key] = null
    result
