types = require('./types')
List = types.List
Doc = types.Doc



prototype = (schema) ->
    result = {}
    for key, val of schema
        if typeof val == 'object'
            if val.type == Doc
                result[key] = prototype(val.schema, false)
            else if val.type == List
                result[key] = []
            else
                result[key] = null
    result


module.exports = prototype