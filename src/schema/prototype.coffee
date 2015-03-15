Doc = require('../doc').Doc
types = require('./types')
List = types.List
Dict = types.Dict



prototype = (schema, top=true) ->
    result = {}
    for key, val of schema
        if typeof val == 'object'
            if val.type == Dict
                result[key] = prototype(val.schema, false)
            else if val.type == List
                result[key] = []
            else
                result[key] = null
    if top
        result = new Doc(result)
    result


module.exports = prototype