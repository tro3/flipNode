assert = require('assert')
mg = require('mongoose')

List =      require('./types/list')
Doc =       require('./types/doc')
Auto =      require('./types/auto')
AutoInit =  require('./types/autoInit')
Serialize = require('./types/serialize')


registerEndpoint = (name, config) ->
    schema = extractSchema(config.schema)
    schema = new mg.Schema(schema)
    mg.model(name, schema)
    

isPrimitive = (cfg) ->
    return true if typeof cfg != 'object'
    return false if !('type' of cfg)
    return !(cfg.type == List || cfg.type == Doc)



expand = (val) ->
    if val instanceof Array   # Encoded as literal Array in config
        val =
            type: List
            schema: val[0]
    if !val.hasOwnProperty('type')  # Encoded as literal Object in config
        val =
            type: Doc
            schema: val[0]
    val

    
    
extractSchema = (schConfig, path="") ->
    schema = {}
    for key, val of schConfig
        if isPrimitive(val)
            if val == Serialize
                1
            else
                schema[key] = val
        else
            val = expand(val)
            assert 'type' of val, "Endpoint config for '#{path}#{key}' needs type"
            
            if val.type == Doc
                assert val.hasOwnProperty('schema'), "Endpoint config for '#{path}#{key}' needs schema"
                schema[key] = extractSchema(val.schema, "#{path}#{key}.")
                
            else if val.type == List
                assert val.hasOwnProperty('schema'), "Endpoint config for '#{path}#{key}' needs schema"
                if isPrimitive(val.schema)
                    schema[key] = [val.schema]
                else
                    schema[key] = [extractSchema(val.schema, "#{path}#{key}.")]
                        
            else
                throw new Error("Malformed schema in #{path}")
    schema
    
    
module.exports = registerEndpoint