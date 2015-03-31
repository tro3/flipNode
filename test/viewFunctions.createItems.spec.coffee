assert = require('chai').assert
sinon = require('sinon')

connect = require('../src/db/qdb')
DbCache = require('../src/db/dbCache')

schema = require('../src/schema')
Schema = schema.Schema
Endpoint = schema.Endpoint
String =  schema.types.String
Dict = schema.types.Dict
List = schema.types.List
Reference = schema.types.Reference
Integer = schema.types.Integer


createItems = require('../src/viewFunctions/createItems')

p = console.log


describe 'viewFunctions.createItems', ->
    conn = null
    req = {}

    before ->
        conn = connect('mongodb://localhost:27017/test')

    after (done) ->
        conn.close()
        .then -> done()

    beforeEach (done) ->
        req.cache = new DbCache(conn)
        conn.insert('flipData.ids', {collection:'test', lastID:0})
        .then -> done()

    afterEach (done) ->
        conn.drop('test')
        .finally -> conn.drop('flipData.ids')
        .finally -> conn.drop('flipData.history')
        .finally -> done()


    it 'creates a simple item', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint {
            a: Integer
        }
        data =
            a:1
        createItems(req, data)
        .then (result) ->
            assert.deepEqual result, {
                status: 'OK'
                items: [{
                    _id:1
                    a:1
                }]
            }
        .then -> conn.findOne('test', {_id:1})
        .then (doc) ->
            assert.deepEqual doc, {
                _id:1
                a:1
            }
            done()
        .catch (err) -> done(err)

    it 'creates two simple items', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint {
            a: Integer
        }
        data = [{a:1},{a:4}]
        createItems(req, data)
        .then (result) ->
            assert.deepEqual result, {
                status: 'OK'
                items: [{
                    _id:1
                    a:1
                },{
                    _id:2
                    a:4
                }]
            }
        .then -> conn.findOne('test', {_id:2})
        .then (doc) ->
            assert.deepEqual doc, {
                _id:2
                a:4
            }
            done()
        .catch (err) -> done(err)

    it 'does not create two simple items when a type error exists in one', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint {
            a: Integer
        }
        data = [{a:1},{a:'q'}]
        createItems(req, data)
        .then (result) ->
            assert.deepEqual result, {
                status: 'ERR'
                errs: [
                    []
                    [{path:'a', msg: "Could not convert 'a' value of 'q'"}]
                ]
            }
        .then -> conn.find('test')
        .then (docs) ->
            assert.equal docs.length, 0
            done()
        .catch (err) -> done(err)

    it 'does not create two simple items when a required error exists in one', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint {
            a: [
                a:
                    type: Integer
                    required: true
            ]
        }
        data = [{a:[{a:1}]},{a:[{a:2},{b:1}]}]
        createItems(req, data)
        .then (result) ->
            assert.deepEqual result, {
                status: 'ERR'
                errs: [
                    []
                    [{path:'a.1.a', msg: "Value required at 'a.1.a'"}]
                ]
            }
        .then -> conn.find('test')
        .then (docs) ->
            assert.equal docs.length, 0
            done()
        .catch (err) -> done(err)

    it 'does not create two simple items when an allowed error exists in one', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint {
            a:
                type: Integer
                allowed: [1,2]
        }
        data = [{a:1},{a:3}]
        createItems(req, data)
        .then (result) ->
            assert.deepEqual result, {
                status: 'ERR'
                errs: [
                    []
                    [{path:'a', msg: "Value '3' at 'a' not allowed"}]
                ]
            }
        .then -> conn.find('test')
        .then (docs) ->
            assert.equal docs.length, 0
            done()
        .catch (err) -> done(err)

    it 'does not create two simple items when an unique error exists in one', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint {
            a:
                a:
                    type: Integer
                    unique: true
        }
        data = [{a:{a:1}},{a:{a:3}}]
        conn.insert('test', {a:{a:3}})
        .then -> createItems(req, data)
        .then (result) ->
            assert.deepEqual result, {
                status: 'ERR'
                errs: [
                    []
                    [{path:'a.a', msg: "Value '3' at 'a.a' is not unique"}]
                ]
            }
        .then -> conn.find('test')
        .then (docs) ->
            assert.equal docs.length, 1
            done()
        .catch (err) -> done(err)

    it 'handles sequential writes', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint {
            a: Integer
        }
        data =
            a:1
        createItems(req, data)
        .then (result) ->
            assert.deepEqual result, {
                status: 'OK'
                items: [{
                    _id:1
                    a:1
                }]
            }
        .then -> conn.find('test')
        .then (docs) ->
            assert.deepEqual docs, [{
                _id:1
                a:1
            }]
        .then -> createItems(req, data)
        .then (result) ->
            assert.deepEqual result, {
                status: 'OK'
                items: [{
                    _id:2
                    a:1
                }]
            }
        .then -> conn.find('test')
        .then (docs) ->
            assert.deepEqual docs, [{
                _id:1
                a:1
            },{
                _id:2
                a:1
            }]
            done()
        .catch (err) -> done(err)

    it 'handles adds create history for single item', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint {
            a: Integer
        }
        data =
            a:1
        createItems(req, data)
        .then (result) ->
            assert.deepEqual result, {
                status: 'OK'
                items: [{
                    _id:1
                    a:1
                }]
            }
        .then -> conn.find('flipData.history')
        .then (docs) ->
            assert.deepEqual docs, [{
                _id:docs[0]._id
                collection: 'test'
                item: 1
                action: 'created'
                new: {_id:1, a:1}
            }]
            done()
        .catch (err) -> done(err)

    it 'handles adds create history for multiple items', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint {
            a: Integer
        }
        data = [{a:2},{a:4}]
        createItems(req, data)
        .then (result) ->
            assert.deepEqual result, {
                status: 'OK'
                items: [{
                    _id:1
                    a:2
                },{
                    _id:2
                    a:4
                }]
            }
        .then -> conn.find('flipData.history')
        .then (docs) ->
            assert.deepEqual docs, [{
                _id:docs[0]._id
                collection: 'test'
                item: 1
                action: 'created'
                new: {_id:1, a:2}
            },{
                _id:docs[1]._id
                collection: 'test'
                item: 2
                action: 'created'
                new: {_id:2, a:4}
            }]
            done()
        .catch (err) -> done(err)
