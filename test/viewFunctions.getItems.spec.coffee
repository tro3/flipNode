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

getItems = require('../src/viewFunctions/getItems')

p = console.log


describe 'viewFunctions.getItems', ->
    conn = null
    req = {}

    before ->
        conn = connect('mongodb://localhost:27017/test')
        conn.insert('refs', [
            {_id:1, name: 'Bob', city: 'Palo Alto'}
            {_id:2, name: 'Fred', city: 'Menlo Park'}
        ])

    after (done) ->
        conn.drop('refs')
        .then -> conn.close()
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
        req.endpoint = new Endpoint {
            a: Number
        }
        req.cache.insert('test', {_id:1, a:1})
        .then -> getItems(req, {_id:1})
        .then (docs) ->
            assert.equal docs.length, 1
            assert.deepEqual docs[0], {
                __proto__: docs[0].__proto__
                _id:1
                _auth: {_edit: true, _delete: true}
                a:1
            }
            done()
        .catch (err) -> done(err)

    it 'retrieves simple items with auth', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint (
            auth:
                edit: (doc) -> doc._id == 1
                delete: false
            schema:
                a: Number
        )
        req.cache.insert('test', [{_id:1, a:1}, {_id:2, a:1}])
        .then -> getItems(req, {a:1})
        .then (docs) ->
            assert.equal docs.length, 2
            assert.deepEqual docs, [{
                __proto__: docs[0].__proto__
                _id:1
                _auth: {_edit: true, _delete: false}
                a:1
            },{
                __proto__: docs[1].__proto__
                _id:2
                _auth: {_edit: false, _delete: false}
                a:1                
            }]
            done()
        .catch (err) -> done(err)

    it 'retrieves nested items with auth', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint (
            schema:
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
                __proto__: docs[0].__proto__
                _id:1
                _auth: {_edit: true, _delete: true}
                a:1
                b:
                    _auth: {_edit: true}
                    c:1
            },{
                __proto__: docs[1].__proto__
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
        req.endpoint = new Endpoint (
            schema:
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
                __proto__: docs[0].__proto__
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

    it 'serializes references', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint (
            schema:
                ref: 
                    type: Reference
                    collection: 'refs'
                    fields: ['name', 'city']
        )
        req.cache.insert('test', {_id:1, ref:1})
        .then -> getItems(req, {_id:1})
        .then (docs) ->
            assert.equal docs.length, 1
            assert.deepEqual docs[0], {
                __proto__: docs[0].__proto__
                _id:1
                _auth: {_edit: true, _delete: true}
                ref:
                    _id: 1
                    name: 'Bob'
                    city: 'Palo Alto'
            }
            done()
        .catch (err) -> done(err)

    it 'handles broken references', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint (
            schema:
                ref: 
                    type: Reference
                    collection: 'refs'
                    fields: ['name', 'city']
        )
        req.cache.insert('test', {_id:1, ref:3})
        .then -> getItems(req, {_id:1})
        .then (docs) ->
            assert.equal docs.length, 1
            assert.deepEqual docs[0], {
                __proto__: docs[0].__proto__
                _id:1
                _auth: {_edit: true, _delete: true}
                ref:
                    _id: 3
                    name: 'broken reference'
                    city: 'broken reference'
            }
            done()
        .catch (err) -> done(err)

    it 'serializes references in nested documents', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint (
            schema:
                nested:
                    ref: 
                        type: Reference
                        collection: 'refs'
                        fields: ['name', 'city']
        )
        req.cache.insert('test', {_id:1, nested:{ref:2}})
        .then -> getItems(req, {_id:1})
        .then (docs) ->
            assert.equal docs.length, 1
            assert.deepEqual docs[0], {
                __proto__: docs[0].__proto__
                _id:1
                _auth: {_edit: true, _delete: true}
                nested:
                    _auth: {_edit: true}
                    ref:
                        _id: 2
                        name: 'Fred'
                        city: 'Menlo Park'
            }
            done()
        .catch (err) -> done(err)

    it 'serializes references in nested documents with auth', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint (
            schema:
                nested:
                    ref: 
                        type: Reference
                        collection: 'refs'
                        fields: ['name', 'city']
                nested2:
                    type: Dict
                    auth:
                        read: false
                    schema:
                        ref: 
                            type: Reference
                            collection: 'refs'
                            fields: ['name', 'city']
        )
        req.cache.insert('test', {_id:1, nested:{ref:2}, nested2:{ref:1}})
        .then -> getItems(req, {_id:1})
        .then (docs) ->
            assert.equal docs.length, 1
            assert.deepEqual docs[0], {
                __proto__: docs[0].__proto__
                _id:1
                _auth: {_edit: true, _delete: true}
                nested:
                    _auth: {_edit: true}
                    ref:
                        _id: 2
                        name: 'Fred'
                        city: 'Menlo Park'
            }
            done()
        .catch (err) -> done(err)

    it 'serializes lists of references', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint (
            schema:
                refs: [
                    type: Reference
                    collection: 'refs'
                    fields: ['name', 'city']
                ]
        )
        req.cache.insert('test', {_id:1, refs:[1,2]})
        .then -> getItems(req, {_id:1})
        .then (docs) ->
            assert.equal docs.length, 1
            assert.deepEqual docs[0], {
                __proto__: docs[0].__proto__
                _id:1
                _auth: {_edit: true, _delete: true}
                refs: [{
                    _id: 1
                    name: 'Bob'
                    city: 'Palo Alto'
                },{
                    _id: 2
                    name: 'Fred'
                    city: 'Menlo Park'
                }]
            }
            done()
        .catch (err) -> done(err)

    it 'serializes references in lists of items', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint (
            schema:
                docs: [
                    ref:
                        type: Reference
                        collection: 'refs'
                        fields: ['name', 'city']
                ]
        )
        req.cache.insert('test', {_id:1, docs:[{_id:1, ref:1}, {_id:2, ref:3}]})
        .then -> getItems(req, {_id:1})
        .then (docs) ->
            assert.equal docs.length, 1
            assert.deepEqual docs[0], {
                __proto__: docs[0].__proto__
                _id:1
                _auth: {_edit: true, _delete: true, docs:true}
                docs: [{
                    _id: 1
                    _auth: {_edit: true, _delete: true}
                    ref:
                        _id: 1
                        name: 'Bob'
                        city: 'Palo Alto'
                },{
                    _id: 2
                    _auth: {_edit: true, _delete: true}
                    ref:
                        _id: 3
                        name: 'broken reference'
                        city: 'broken reference'
                }]
            }
            done()
        .catch (err) -> done(err)
    
    it 'serializes lists of references in lists of items', (done) ->
        req.collection = 'test'
        req.endpoint = new Endpoint (
            schema:
                docs: [
                    refs: [
                        type: Reference
                        collection: 'refs'
                        fields: ['name', 'city']
                    ]
                ]
        )
        req.cache.insert('test', {_id:1, docs:[{_id:1, refs:[1]}, {_id:2, refs:[2,3]}]})
        .then -> getItems(req, {_id:1})
        .then (docs) ->
            assert.equal docs.length, 1
            assert.deepEqual docs[0], {
                __proto__: docs[0].__proto__
                _id:1
                _auth: {_edit: true, _delete: true, docs:true}
                docs: [{
                    _id: 1
                    _auth: {_edit: true, _delete: true}
                    refs: [
                        _id: 1
                        name: 'Bob'
                        city: 'Palo Alto'
                    ]
                },{
                    _id: 2
                    _auth: {_edit: true, _delete: true}
                    refs: [{
                        _id: 2
                        name: 'Fred'
                        city: 'Menlo Park'
                    },{
                        _id: 3
                        name: 'broken reference'
                        city: 'broken reference'
                    }]
                }]
            }
            done()
        .catch (err) -> done(err)
