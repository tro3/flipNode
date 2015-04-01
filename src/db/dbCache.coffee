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
    return "#{collection}?#{hashObj(query)}?#{hashObj(options)}"



class DbCache
    constructor: (db) ->
        @db = db
        @lookup = {}
            
    find: (collection, query={}, options={}) ->
        hash = hashQuery(collection, query, options)
        if hash of @lookup
            return q.Promise.resolve(@lookup[hash])
        
        @db.find(collection, query, options)
        .then (docs) =>
            @lookup[hash] = docs
            docs.forEach (doc) =>
                @lookup[hashQuery(collection, {_id:doc._id})] = [doc]
            docs
            

    findOne: (collection, query={}, options={}) ->
        hash = hashQuery(collection, query, options)
        if hash of @lookup
            return q.Promise.resolve(@lookup[hash][0])

        @db.findOne(collection, query, options)
        .then (doc) =>
            return null if !doc
            @lookup[hash] = [doc]
            @lookup[hashQuery(collection, {_id:doc._id})] = [doc]
            doc


    
    insert: (collection, docs) ->
        @db.insert(collection, docs)

    update: (collection, spec, update, options) ->
        @db.update(collection, spec, update, options)

    updateMany: (collection, spec, update, options) ->
        @db.updateMany(collection, spec, update, options)
    
    remove: (collection, spec) ->
        @db.remove(collection, spec)

    count: (collection, query={}, options={}) ->
        hash = hashQuery(collection, query, options)
        if hash of @lookup
            return q.Promise.resolve(@lookup[hash].length)
        @db.count(collection, query, options)

module.exports = DbCache



