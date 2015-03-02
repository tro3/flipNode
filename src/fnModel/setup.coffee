assert = require('assert')
mg = require('mongoose')

List =     require('./types/list')
Doc =      require('./types/subdoc')
Auto =     require('./types/auto')
AutoInit = require('./types/autoInit')


registerEndpoint = (name, config) ->
    schema = extractSchema(config.schema)
    mg.model(name, schema)
    

    
extractSchema = (schConfig, path="") ->
    schema = {}
    for key, val of schConfig
        if typeof val != 'object'
            schema[key] = val
        else
            if val instanceof Array   # Encoded as literal Array in config
                val =
                    type: List
                    schema: val[0]
            if !val.hasOwnProperty('type')  # Encoded as literal Object in config
                val =
                    type: Doc
                    schema: val[0]
            
            assert val.hasOwnProperty('type'), "Endpoint config for '#{path}#{key}' needs type"
            if val.type == Doc
                assert val.hasOwnProperty('schema'), "Endpoint config for '#{path}#{key}' needs schema"
                schema[key] = extractSchema(val.schema, "#{path}#{key}.")
            else if val.type == List
                assert val.hasOwnProperty('schema'), "Endpoint config for '#{path}#{key}' needs schema"
                if typeof val.schema != 'object' || val.schema.hasOwnProperty('type')
                    schema[key] = [val.schema]
                else
                    schema[key] = [extractSchema(val.schema, "#{path}#{key}.")]
            else
                schema[key] = val
    debugger
    schema
    
    
module.exports = registerEndpoint