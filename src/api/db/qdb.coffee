client = require('mongodb').MongoClient
q = require('q')

p = console.log


defaultConn = 'mongodb://localhost:27017/test'

class qDB
    constructor: (connString=defaultConn) ->
        @db = null
        @connected = @connect(connString)

    connect: (connString) ->
        q.Promise (resolve, reject) ->
            client.connect connString, (err, resp) ->
                reject err if err
                @db = resp
                resolve()
                
    collections: ->
        @connected.then -> q.Promise (resolve, reject) ->
            @db.collections (err, resp) ->
                reject err if err
                resolve(resp)
    
    find: (collection, query={}, options={}) ->
        @connected.then -> q.Promise (resolve, reject) ->
            @db.collection(collection).find(query, options).toArray (err, resp) ->
                reject err if err
                resolve(resp)

    findOne: (collection, query={}, options={}) ->
        @connected.then -> q.Promise (resolve, reject) ->
            @db.collection(collection).findOne query, options, (err, resp) ->
                reject err if err
                resolve(resp)
 
    count: (collection, query={}, options={}) ->
        @connected.then -> q.Promise (resolve, reject) ->
            @db.collection(collection).find(query, options).count (err, resp) ->
                reject err if err
                resolve(resp)
    
    insert: (collection, docs) ->
        docs = [docs] if !(docs instanceof Array)
        return q() if !docs.length
        @connected.then -> q.Promise (resolve, reject) ->
            @db.collection(collection).insertMany docs, (err, resp) ->
                reject err if err
                resolve(resp)

    update: (collection, spec={}, update={}, options={}) ->
        @connected.then -> q.Promise (resolve, reject) ->
            @db.collection(collection).updateOne spec, update, options, (err, resp) ->
                reject err if err
                resolve(resp)

    updateMany: (collection, spec={}, update={}, options={}) ->
        @connected.then -> q.Promise (resolve, reject) ->
            @db.collection(collection).updateMany spec, update, options, (err, resp) ->
                reject err if err
                resolve(resp)
    
    remove: (collection, query) ->
        @connected.then -> q.Promise (resolve, reject) ->
            @db.collection(collection).remove query, (err, resp) ->
                reject err if err
                resolve(resp)

    drop: (collection) ->
        @connected.then -> q.Promise (resolve, reject) ->
            @db.collection(collection).drop (err, resp) ->
                reject err if err
                resolve(resp)
    
    close: () ->
        @connected.then -> q.Promise (resolve, reject) ->
            @db.close()
            resolve()


module.exports = (connString) -> new qDB(connString)
