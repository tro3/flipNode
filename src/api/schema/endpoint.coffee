fp = require 'flipFP'
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
            
        for perm in ['create','read','edit','delete']
            @auth[perm] = true if !(perm of @auth)
            

        collect = (fcn, condition) =>
            get = (x) => @schema.get(x)
            lst = fcn(@schema, condition)
            fp.zipObj lst, fp.map get, lst
            
        isDocList = (x) -> x.type == types.List && 'schema' of x

        @paths =
            alloweds:   collect paths.withProp,     'allowed'
            defaults:   collect paths.withProp,     'default'
            requireds:  collect paths.withTrueProp, 'required'
            uniques:    collect paths.withTrueProp, 'unique'
            references: collect paths.ofType,       types.Reference
            autos:      collect paths.ofType,       types.Auto
            autoInits:  collect paths.ofType,       types.AutoInit
            docs:       collect paths.ofType,       types.Doc
            dates:      collect paths.ofType,       types.Date
            lists:      collect paths.ifTrue,       isDocList



module.exports = Endpoint