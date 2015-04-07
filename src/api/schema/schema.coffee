expand = require('./expand')
types = require('./types') 
Doc = types.Doc
List = types.List
Integer = types.Integer

p = console.log
        
class Schema
    constructor: (data) ->
        expand(data, @)

    # Will always return a typed object: {type: String, required:true}
    # or {type:List, schema:{...}, auth:{...}}
    get: (path) ->
        parts = path.split('.')
        
        current = {type: Doc, schema: @}
        for part in parts
            if current.type == Doc
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
