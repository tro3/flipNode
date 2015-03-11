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

hashQuery = (query, options={}) ->
    return "#{hashObj(query)}?#{hashObj(options)}"



class DbCache
    constructor: (db) ->
        @db = db
        @cache = {}
            
    find: (collection, query={}, options={}) ->
        hash = hashQuery(query, options)
        if hash of @cache
            return q.Promise.resolve(@cache[hash])
        
        @db.find(collection, query, options)
        .then (docs) =>
            @cache[hash] = docs
            docs.forEach (doc) =>
                @cache[hashQuery({_id:doc._id})] = [doc]
            docs
            

    findOne: (collection, query={}, options={}) ->
        hash = hashQuery(query, options)
        if hash of @cache
            return q.Promise.resolve(@cache[hash][0])
        
        @db.findOne(collection, query, options)
        .then (doc) =>
            @cache[hash] = [doc]
            @cache[hashQuery({_id:doc._id})] = [doc]
            doc


    
    insert: (collection, docs) ->
        @db.insert(collection, docs)

    update: (collection, spec, update, options) ->
        @db.update(collection, spec, update, options)

    updateMany: (collection, spec, update, options) ->
        @db.updateMany(collection, spec, update, options)
    
    remove: (collection, spec) ->
        @db.remove(collection, spec)


module.exports = DbCache



