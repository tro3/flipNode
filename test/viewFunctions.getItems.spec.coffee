assert = require('chai').assert
sinon = require('sinon')

connect = require('../src/db/qdb')
DbCache = require('../src/db/dbCache')
schema = require('../src/schema')
Schema = schema.Schema
String =  schema.types.String
Dict = schema.types.Dict
List = schema.types.List

getItems = require('../src/viewFunctions/common').getItems

p = console.log


describe.only 'viewFunctions.getItems', ->
    conn = null
    req = {}

    before ->
        conn = connect('mongodb://localhost:27017/test')

    after (done) ->
        conn.close()
        .then -> done()

    beforeEach ->
        req.cache = new DbCache(conn)
        spy1 = sinon.spy(conn, 'find')
        spy2 = sinon.spy(conn, 'findOne')

    afterEach (done) ->
        conn.find.restore()
        conn.findOne.restore()
        conn.drop('test', {})
        .then -> done()

    callCount = -> spy1.callCount + spy2.callCount


    it 'retrieves simple item', (done) ->
        req.collection = 'test'
        req.endpoint =
            schema: new Schema(
                a: Number
            )
        req.cache.insert('test', {_id:1, a:1})
        .then -> getItems(req, {_id:1})
        .then (docs) ->
            assert.equal docs.length, 1
            assert.deepEqual docs[0], {
                _id:1
                _auth: {_edit: true, _delete: true}
                a:1
            }
            done()
        .catch (err) -> done(err)


    it 'retrieves simple items with auth', (done) ->
        req.collection = 'test'
        req.endpoint =
            auth:
                edit: (doc) -> doc._id == 1
                delete: false
            schema: new Schema(
                a: Number
            )
        req.cache.insert('test', [{_id:1, a:1}, {_id:2, a:1}])
        .then -> getItems(req, {a:1})
        .then (docs) ->
            assert.equal docs.length, 2
            assert.deepEqual docs, [{
                _id:1
                _auth: {_edit: true, _delete: false}
                a:1
            },{
                _id:2
                _auth: {_edit: false, _delete: false}
                a:1                
            }]
            done()
        .catch (err) -> done(err)


    it 'retrieves nested items with auth', (done) ->
        req.collection = 'test'
        req.endpoint =
            schema: new Schema(
                a: Number
                b:
                    type: Dict
                    auth:
                        edit: (doc, root) -> root._id == 1
                    schema: 
                        c: Number
            )
        req.cache.insert('test', [{_id:1, a:1, b:{c:1}}, {_id:2, a:1, b:{c:1}}])
        .then -> getItems(req, {a:1})
        .then (docs) ->
            assert.equal docs.length, 2
            assert.deepEqual docs, [{
                _id:1
                _auth: {_edit: true, _delete: true}
                a:1
                b:
                    _auth: {_edit: true}
                    c:1
            },{
                _id:2
                _auth: {_edit: true, _delete: true}
                a:1
                b:
                    _auth: {_edit: false}
                    c:1
            }]
            done()
        .catch (err) -> done(err)


    it 'retrieves lists of items with auth', (done) ->
        req.collection = 'test'
        req.endpoint =
            schema: new Schema(
                a: Number
                b:
                    type: List
                    auth:
                        create: false
                        edit: (doc) -> doc.c == 1
                        delete: false
                    schema: 
                        c: Number
            )
        req.cache.insert('test', {_id:1, a:1, b:[{c:1},{c:2}]})
        .then -> getItems(req, {a:1})
        .then (docs) ->
            assert.equal docs.length, 1
            assert.deepEqual docs, [{
                _id:1
                _auth: {_edit: true, _delete: true, b: false}
                a:1
                b: [{
                    _auth: {_edit: true, _delete: false}
                    c:1
                },{
                    _auth: {_edit: false, _delete: false}
                    c:2
                }]
            }]
            done()
        .catch (err) -> done(err)
