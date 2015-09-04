q = require('q')
ObjectID = require('mongodb').ObjectID
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

deepcopy = (obj) ->
    if typeof obj != 'object'
        return obj
    if obj == null
        return obj
    if obj instanceof Array
        return (deepcopy(x) for x in obj)
    if obj instanceof Date
        return new Date(obj)
    result = {}
    for key, val of obj
        if val instanceof ObjectID
            result[key] = deepcopy(val)
            result[key].__proto__ = val.proto
        else
            result[key] = deepcopy(val)
    result


resolve = q.Promise.resolve


class DbCache
    constructor: (db) ->
        @db = db
        @lookup = {}

    isCached: (hash) ->
        return false if !(hash of @lookup)
        @lookup[hash].every (x) -> x._id != null
        
    setCache: (hash, collection, docs) ->
        @lookup[hash] = docs
        docs.forEach (doc) =>
            indHash = hashQuery(collection, {_id:doc._id})
            @lookup[indHash] = [doc]

    resetCache: (hash) ->
        if hash of @lookup
            @lookup[hash].forEach (x) -> x._id = null


    find: (collection, query={}, options={}) ->
        hash = hashQuery(collection, query, options)

        if !@isCached(hash)
            tmpQ = @db.find(collection, query, options)
            .then (docs) => @setCache(hash, collection, docs)
        else
            tmpQ = resolve()
        return tmpQ.then => deepcopy(@lookup[hash])


    findOne: (collection, query={}, options={}) ->
        hash = hashQuery(collection, query, options)
        if !@isCached(hash)
            tmpQ = @db.findOne(collection, query, options)
            .then (doc) =>
                return false if !doc
                @setCache(hash, collection, [doc])
                true
        else
            tmpQ = resolve(true)
        return tmpQ.then (found) =>
            if found then deepcopy(@lookup[hash][0]) else null


    count: (collection, query={}, options={}) ->
        hash = hashQuery(collection, query, options)
        return resolve(@lookup[hash].length) if @isCached(hash)
        @db.count(collection, query, options)


    insert: (collection, docs) ->
        @db.insert(collection, docs)


    update: (collection, spec, update, options) ->
        hash = hashQuery(collection, spec, {})
        @resetCache(hash)
        @db.update(collection, spec, update, options)


    updateMany: (collection, spec, update, options) ->
        hash = hashQuery(collection, spec, {})
        @resetCache(hash)
        @db.updateMany(collection, spec, update, options)


    remove: (collection, spec) ->
        hash = hashQuery(collection, spec, {})
        @resetCache(hash)
        @db.remove(collection, spec)


module.exports = DbCache