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
            alloweds: {}
            requireds: {}
            uniques: {}
            autos: {}
            autoInits: {}
            docs: {}
            lists: {}
            
        for path in paths.ofType(@schema, types.Reference)
            @paths.references[path] = @schema.get(path)
        
        for path in paths.withProp(@schema, 'allowed')
            @paths.alloweds[path] = @schema.get(path)

        for path in paths.withTrueProp(@schema, 'required')
            @paths.requireds[path] = @schema.get(path)

        for path in paths.withTrueProp(@schema, 'unique')
            @paths.uniques[path] = @schema.get(path)

        for path in paths.ofType(@schema, types.Auto)
            @paths.autos[path] = @schema.get(path)

        for path in paths.ofType(@schema, types.AutoInit)
            @paths.autoInits[path] = @schema.get(path)

        for path in paths.ofType(@schema, types.Dict)
            @paths.docs[path] = @schema.get(path)

        for path in paths.ifTrue(@schema, (x) -> x.type == types.List && 'schema' of x)
            @paths.lists[path] = @schema.get(path)


module.exports = Endpoint