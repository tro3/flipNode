Schema = require('./schema')
paths = require('./paths')
types = require('./types')
p = console.log

class Endpoint
    constructor: (config) ->
        if !('schema' of config)
            @schema = new Schema(config)
            @auth = {}
        else
            @schema = new Schema(config.schema)
            @auth = if 'auth' of config then config.auth else {}

        @paths =
            references: {}
        for path in paths.ofType(@schema, types.Reference)
            @paths.references[path] = @schema.get(path)
        


module.exports = Endpoint