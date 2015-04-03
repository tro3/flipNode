q = require('q')
connect = require('./qdb')
p = console.log

hashObj = (obj) ->
    if typeof obj != 'object'
        return "#{obj}"
    keys = Object.keys(obj)
    keys.sort()
    result = []
    for key in keys
        val = obj[key]
        if val instanceof Array
            val = "[#{[hashQuery(x) for x in val].join()}]"
        else if typeof val == 'object'
            val = "{#{hashQuery(val)}}"
        result.push "#{key}:#{val}"
    result.join()

hashQuery = (collection, query, options={}) ->
    JSON.stringify(
        collection: collection
        query: query
        options: options
    )




class DbCache
    constructor: (db) ->
        @db = db
        @lookup = {}
        @validCache = {}

    isCached: (hash) ->
        if !(hash of @validCache)
            return false
        @validCache[hash]
            
    find: (collection, query={}, options={}) ->
        hash = hashQuery(collection, query, options)
        if @isCached(hash)
            return q.Promise.resolve(@lookup[hash])
        
        @db.find(collection, query, options)
        .then (docs) =>
            @lookup[hash] = docs
            @validCache[hash] = true
            docs.forEach (doc) =>
                indHash = hashQuery(collection, {_id:doc._id})
                @lookup[indHash] = [doc]
                @validCache[indHash] = true
            docs
            

    findOne: (collection, query={}, options={}) ->
        hash = hashQuery(collection, query, options)
        if @isCached(hash)
            return q.Promise.resolve(@lookup[hash][0])

        @db.findOne(collection, query, options)
        .then (doc) =>
            return null if !doc
            @lookup[hash] = [doc]
            @validCache[hash] = true
            indHash = hashQuery(collection, {_id:doc._id})
            @lookup[indHash] = [doc]
            @validCache[indHash] = true
            doc

    count: (collection, query={}, options={}) ->
        hash = hashQuery(collection, query, options)
        if @isCached(hash)
            return q.Promise.resolve(@lookup[hash].length)
        @db.count(collection, query, options)

    
    insert: (collection, docs) ->
        @db.insert(collection, docs)

    update: (collection, spec, update, options) ->
        hash = hashQuery(collection, spec, {})
        if hash of @validCache
            @validCache[hash] = false
        @db.update(collection, spec, update, options)

    updateMany: (collection, spec, update, options) ->
        @db.updateMany(collection, spec, update, options)
    
    remove: (collection, spec) ->
        hash = hashQuery(collection, spec, {})
        if hash of @lookup
            @lookup[hash][0]._id = null
        @db.remove(collection, spec)


module.exports = DbCache



