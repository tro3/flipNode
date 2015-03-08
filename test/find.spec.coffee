assert = require('chai').assert
client = require('mongodb').MongoClient
q = require('q')

p = console.log

schema = require('../src/schema')
Schema = schema.Schema
String =  schema.types.String
Dict = schema.types.Dict
List = schema.types.List
Auth = require('../src/auth')

find = require('../src/db').find




qConnect = () ->
    q.Promise (resolve, reject) ->
        client.connect 'mongodb://localhost:27017/test', (err, db) ->
            reject err if err
            resolve db

qClose = (db) ->
    q.Promise (resolve, reject) ->
        db.collection('test').drop (err) ->
            db.close()
            resolve()


qInsert = (db, docs) ->
    docs = [docs] if !(docs instanceof Array)
    q.Promise (resolve, reject) ->
        db.collection('test').insertMany docs, (err, resp) ->
            reject err if err
            resolve(resp.insertedIds)




describe.only 'db find', ->
    db = null
    id = null

    before (done) ->
        qConnect().then (x) ->
            db = x
            done()

    after (done) ->
        qClose(db).then ->
            done()

    it 'handles simple object', (done) ->
        endp =
            schema: new Schema(
                name: String
            )
        qInsert(db, {name: "Bob"})
        .then (ids) ->
            id = ids[0]
            find(db, 'test', endp)
        .then (docs) ->
            assert.deepEqual docs[0].projection, {
                _id: id
                _auth:
                    _edit: true
                    _delete: true
                name: 'Bob'
            }
            done()
        .catch (err) -> done(err)


