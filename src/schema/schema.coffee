expand = require('./expand')
Dict = require('./types').Dict
List = require('./types').List
p = console.log
        
class Schema
    constructor: (data) ->
        expand(data, @)

    # Will always return a typed object: {type: String, required:true}
    # or {type:List, schema:{...}, auth:{...}}
    get: (path) ->
        parts = path.split('.')
        
        current = {type: Dict, schema: @}
        for part in parts
            if current.type == Dict
                if part of current.schema
                    current = current.schema[part]
                else
                    return undefined 
            else if current.type == List and 'schema' of current
                if part of current.schema
                    current = current.schema[part]
                else if parseInt(part) != NaN
                    # Do nothing - move to the next part
                else
                    return undefined 
            else
                return undefined
        return current
            
            


module.exports = Schema

#module.exports = (data) ->
#    sch = expand(data)
#    proto = new Object
#    proto.get = (path) -> get(path, sch)
#    sch.__proto__ = proto
#    sch
