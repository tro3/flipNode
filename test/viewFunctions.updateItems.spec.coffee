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


updateItems = require('../src/viewFunctions/updateItems')

p = console.log


describe 'viewFunctions.updateItems', ->
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


    it 'updates a simple item', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint {
            a: Integer
        }
        data =
            _id:1
            a:1
        conn.insert('test', data)
        .then -> data.a = 2
        .then -> updateItems(req, data)
        .then (result) ->
            assert.deepEqual result, {
                status: 'OK'
                items: [{
                    _id:1
                    a:2
                }]
            }
        .then -> conn.findOne('test', {_id:1})
        .then (doc) ->
            assert.deepEqual doc, {
                _id:1
                a:2
            }
            done()
        .catch (err) -> done(err)

    it 'updates two simple items', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint {
            a: Integer
        }
        data = [{_id:1,a:1},{_id:2,a:4}]
        conn.insert('test', data)
        .then ->
            data[0].a = 2
            data[1].a = 3
        .then -> updateItems(req, data)
        .then (result) ->
            assert.deepEqual result, {
                status: 'OK'
                items: [{
                    _id:1
                    a:2
                },{
                    _id:2
                    a:3
                }]
            }
        .then -> conn.findOne('test', {_id:2})
        .then (doc) ->
            assert.deepEqual doc, {
                _id:2
                a:3
            }
            done()
        .catch (err) -> done(err)

    it 'does not update two simple items when a type error exists in one', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint {
            a: Integer
        }
        data = [{_id:1,a:1},{_id:2,a:4}]
        conn.insert('test', data)
        .then ->
            data[0].a = 2
            data[1].a = 'q'
        .then -> updateItems(req, data)
        .then (result) ->
            assert.deepEqual result, {
                status: 'ERR'
                errs: [
                    []
                    [{path:'a', msg: "Could not convert 'a' value of 'q'"}]
                ]
            }
        .then -> conn.findOne('test', {_id:1})
        .then (doc) ->
            assert.equal doc.a, 1
            done()
        .catch (err) -> done(err)

    it 'does not update two simple items when a required error exists in one', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint {
            a: [
                a:
                    type: Integer
                    required: true
            ]
        }
        data = [{_id:1,a:[{_id:1, a:1}]},{_id:2,a:[{_id:1, a:2},{_id:2, a:1}]}]
        conn.insert('test', data)
        .then ->
            data[0].a[0].a = 2
            data[1].a.push {b:1}
        .then -> updateItems(req, data)
        .then (result) ->
            assert.deepEqual result, {
                status: 'ERR'
                errs: [
                    []
                    [{path:'a.2.a', msg: "Value required at 'a.2.a'"}]
                ]
            }
        .then -> conn.findOne('test', {_id:1})
        .then (doc) ->
            assert.equal doc.a[0].a, 1
            done()
        .catch (err) -> done(err)

    it 'does not update two simple items when an allowed error exists in one', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint {
            a:
                type: Integer
                allowed: [1,2]
        }
        data = [{_id:1,a:1},{_id:2,a:2}]
        conn.insert('test', data)
        .then ->
            data[0].a = 2
            data[1].a = 3
        .then -> updateItems(req, data)
        .then (result) ->
            assert.deepEqual result, {
                status: 'ERR'
                errs: [
                    []
                    [{path:'a', msg: "Value '3' at 'a' not allowed"}]
                ]
            }
        .then -> conn.findOne('test', {_id:1})
        .then (doc) ->
            assert.equal doc.a, 1
            done()
        .catch (err) -> done(err)

    it 'does not update two simple items when an unique error exists in one', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint {
            a:
                a:
                    type: Integer
                    unique: true
        }
        data = [{_id:1,a:{a:3}},{_id:2,a:{a:4}}]
        conn.insert('test', data)
        .then ->
            data[0].a.a = 2
            data[1].a.a = 3
        .then -> updateItems(req, data)
        .then (result) ->
            assert.deepEqual result, {
                status: 'ERR'
                errs: [
                    []
                    [{path:'a.a', msg: "Value '3' at 'a.a' is not unique"}]
                ]
            }
        .then -> conn.findOne('test', {_id:1})
        .then (doc) ->
            assert.equal doc.a.a, 3
            done()
        .catch (err) -> done(err)

    it 'adds update history for single item', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint {
            a: Integer
        }
        data = {_id:1,a:1}
        conn.insert('test', data)
        .then -> data.a = 2
        .then -> updateItems(req, data)
        .then (result) ->
            assert.deepEqual result, {
                status: 'OK'
                items: [{
                    _id:1
                    a:2
                }]
            }
        .then -> conn.find('flipData.history')
        .then (docs) ->
            assert.deepEqual docs, [{
                _id:docs[0]._id
                collection: 'test'
                item: 1
                action: 'field changed'
                objPath: ''
                field: 'a'
                old: 1
                new: 2
            }]
            done()
        .catch (err) -> done(err)

    it 'adds update history for multiple items', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint {
            a: Integer
        }
        data = [{_id:1, a:2},{_id:2, a:4}]
        conn.insert('test', data)
        .then ->
            data[0].a = 1
            data[1].a = 2
        .then -> updateItems(req, data)
        .then (result) ->
            assert.deepEqual result, {
                status: 'OK'
                items: [{
                    _id:1
                    a:1
                },{
                    _id:2
                    a:2
                }]
            }
        .then -> conn.find('flipData.history')
        .then (docs) ->
            assert.deepEqual docs, [{
                    _id:docs[0]._id
                    collection: 'test'
                    item: 1
                    action: 'field changed'
                    objPath: ''
                    field: 'a'
                    old: 2
                    new: 1
                },{
                    _id:docs[1]._id
                    collection: 'test'
                    item: 2
                    action: 'field changed'
                    objPath: ''
                    field: 'a'
                    old: 4
                    new: 2
            }]
            done()
        .catch (err) -> done(err)

    it 'does update history for fields with Log false'