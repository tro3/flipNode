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
    if obj instanceof Array
        return (deepcopy(x) for x in obj)
    result = {}
    for key, val of obj
        if val instanceof Date
            result[key] = deepcopy(val)
            result[key].__proto__ = val.proto
        else if val instanceof ObjectID
            result[key] = deepcopy(val)
            result[key].__proto__ = val.proto
        else
            result[key] = deepcopy(val)
    result



class DbCache
    constructor: (db) ->
        @db = db
        @lookup = {}

    isCached: (hash) ->
        if !(hash of @lookup)
            return false
        @lookup[hash].every (x) -> x._id != null

    find: (collection, query={}, options={}) ->
        hash = hashQuery(collection, query, options)

        if !@isCached(hash)
            tmpQ = @db.find(collection, query, options)
            .then (docs) =>
                @lookup[hash] = docs
                docs.forEach (doc) =>
                    indHash = hashQuery(collection, {_id:doc._id})
                    @lookup[indHash] = [doc]
        else
            tmpQ = q.Promise.resolve()
        return tmpQ.then => deepcopy(@lookup[hash])


    findOne: (collection, query={}, options={}) ->
        hash = hashQuery(collection, query, options)
        if !@isCached(hash)
            tmpQ = @db.findOne(collection, query, options)
            .then (doc) =>
                return false if !doc
                @lookup[hash] = [doc]
                indHash = hashQuery(collection, {_id:doc._id})
                @lookup[indHash] = [doc]
                true
        else
            tmpQ = q.Promise.resolve(true)
        return tmpQ.then (found) =>
            if found then deepcopy(@lookup[hash][0]) else null


    count: (collection, query={}, options={}) ->
        hash = hashQuery(collection, query, options)
        if @isCached(hash)
            return q.Promise.resolve(@lookup[hash].length)
        @db.count(collection, query, options)


    insert: (collection, docs) ->
        @db.insert(collection, docs)


    update: (collection, spec, update, options) ->
        hash = hashQuery(collection, spec, {})
        if hash of @lookup
            @lookup[hash].forEach (x) -> x._id = null
        @db.update(collection, spec, update, options)


    updateMany: (collection, spec, update, options) ->
        hash = hashQuery(collection, spec, {})
        if hash of @lookup
            @lookup[hash].forEach (x) -> x._id = null
        @db.updateMany(collection, spec, update, options)


    remove: (collection, spec) ->
        hash = hashQuery(collection, spec, {})
        if hash of @lookup
            @lookup[hash].forEach (x) -> x._id = null
        @db.remove(collection, spec)


module.exports = DbCache