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

qClear = (db) ->
    q.Promise (resolve, reject) ->
        db.collection('test').remove {}, (err) ->
            resolve()

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




describe 'db find', ->
    db = null
    id = null

    before (done) ->
        qConnect().then (x) ->
            db = x
            done()

    after (done) ->
        qClose(db).then ->
            done()

    beforeEach (done) ->
        qClear(db).then ->
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
                _auth: {_edit: true, _delete: true}
                name: 'Bob'
            }
            done()
        .catch (err) -> done(err)

    it 'handles nested objects and lists', (done) ->
        endp =
            schema: new Schema(
                nested:
                    name: String
                    list: [
                        name: String
                    ]
            )
        qInsert(db, {nested:{name:"Bob",list:[{name:'Fred'}]}})
        .then (ids) ->
            id = ids[0]
            find(db, 'test', endp)
        .then (docs) ->
            assert.deepEqual docs[0].projection, {
                _id: id
                _auth: {_edit: true, _delete: true}
                nested:
                    _auth: {_edit: true, list: true}
                    name: 'Bob'
                    list: [
                        _auth: {_edit: true, _delete: true}                        
                        name: 'Fred'
                    ]
            }
            done()
        .catch (err) -> done(err)

    it 'handles nested objects and lists with functions', (done) ->
        endp =
            schema: new Schema(
                nested:
                    type: Dict
                    auth:
                        edit: false
                    schema:
                        name: String
                        list:
                            type: List
                            auth:
                                edit: (el) -> el.name == 'Fred'
                            schema:
                                name: String
            )
        qInsert(db, {nested:{name:"Bob",list:[{name:'Fred'},{name:'Fred2'}]}})
        .then (ids) ->
            id = ids[0]
            find(db, 'test', endp)
        .then (docs) ->
            assert.deepEqual docs[0].projection, {
                _id: id
                _auth: {_edit: true, _delete: true}
                nested:
                    _auth: {_edit: false, list: true}
                    name: 'Bob'
                    list: [{
                        _auth: {_edit: true, _delete: true}                        
                        name: 'Fred'
                    },{
                        _auth: {_edit: false, _delete: true}                        
                        name: 'Fred2'
                    }]
            }
            done()
        .catch (err) -> done(err)

    it.skip 'handles read auth with nested objects and lists with functions', (done) ->
        endp =
            schema: new Schema(
                nested:
                    type: Dict
                    auth:
                        edit: false
                    schema:
                        name: String
                        list:
                            type: List
                            auth:
                                read: (el) -> el.name == 'Fred'
                            schema:
                                name: String
                nested2:
                    type: Dict
                    auth:
                        read: (el) -> el.name == 'Fred'
                    schema:
                        name: String
            )
        qInsert(db, {nested:{name:"Bob",list:[{name:'Fred'},{name:'Fred2'}]},nested2:{name:String}})
        .then (ids) ->
            id = ids[0]
            find(db, 'test', endp)
        .then (docs) ->
            assert.deepEqual docs[0].projection, {
                _id: id
                _auth: {_edit: true, _delete: true}
                nested:
                    _auth: {_edit: false, list: true}
                    name: 'Bob'
                    list: [{
                        _auth: {_edit: false, _delete: true}                        
                        name: 'Fred'
                    }]
            }
            done()
        .catch (err) -> done(err)
