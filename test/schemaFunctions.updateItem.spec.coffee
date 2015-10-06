assert = require('chai').assert
sinon = require('sinon')

connect = require('../src/api/db/qdb')
DbCache = require('../src/api/db/dbCache')

schema = require('../src/api/schema')
Schema = schema.Schema
Endpoint = schema.Endpoint
String =  schema.types.String
Doc = schema.types.Doc
List = schema.types.List
Reference = schema.types.Reference
Integer = schema.types.Integer


updateItem = require('../src/api/schemaFunctions/updateItem')

p = console.log


describe 'schemaFunctions.updateItem', ->
    conn = null
    env = null

    before ->
        conn = connect('mongodb://localhost:27017/test')

    after (done) ->
        conn.close()
        .then -> done()

    beforeEach (done) ->
        env =
            collection: 'test'
            cache: new DbCache(conn)
            errs: []
        conn.insert('flipData.ids', {collection:'test', lastID:0})
        .then -> done()

    afterEach (done) ->
        conn.drop('test')
        .finally -> conn.drop('flipData.ids')
        .finally -> conn.drop('flipData.history')
        .finally -> done()


    it 'updates a simple item', (done) ->
        env.endpoint = new Endpoint {
            a: Integer
        }
        data =
            _id:1
            a:1
        conn.insert('test', data)
        .then -> data.a = 2
        .then -> updateItem(env, data)
        .then (result) ->
            assert.equal result.errs.length, 0
            assert.property result, 'tid'
            assert.property result, 'mongoResponse'
            assert.deepEqual result.doc, {
                _id:1
                a:2
            }
        .then -> conn.findOne('test', {_id:1})
        .then (doc) ->
            assert.deepEqual doc, {
                _id:1
                a:2
            }
            done()
        .catch (err) -> done(err)


    it 'does not update simple item when a type error exists', (done) ->
        env.endpoint = new Endpoint {
            a: Integer
        }
        data = {_id:1,a:1}
        conn.insert('test', data)
        .then ->
            data.a = 'q'
        .then -> updateItem(env, data)
        .then (result) ->
            assert.equal result.errs.length, 1
            assert.deepEqual result.errs, [
                {path:'a', msg: "Could not convert 'a' value of 'q'"}
            ]
        .then -> conn.findOne('test', {_id:1})
        .then (doc) ->
            assert.equal doc.a, 1
            done()
        .catch (err) -> done(err)


    it 'does not update simple item when a required error exists', (done) ->
        env.endpoint = new Endpoint {
            a: [
                a:
                    type: Integer
                    required: true
            ]
        }
        data = {_id:2,a:[{_id:1, a:2},{_id:2, a:1}]}
        conn.insert('test', data)
        .then ->
            data.a.push {b:1}
        .then -> updateItem(env, data)
        .then (result) ->
            assert.equal result.errs.length, 1
            assert.deepEqual result.errs, [
                {path:'a.2.a', msg: "Value required at 'a.2.a'"}
            ]
        .then -> conn.findOne('test', {_id:2})
        .then (doc) ->
            assert.equal doc.a.length, 2
            done()
        .catch (err) -> done(err)

    it 'does not update simple item when an allowed error exists', (done) ->
        env.endpoint = new Endpoint {
            a:
                type: Integer
                allowed: [1,2]
        }
        data = {_id:1,a:1}
        conn.insert('test', data)
        .then ->
            data.a = 3
        .then -> updateItem(env, data)
        .then (result) ->
            assert.equal result.errs.length, 1
            assert.deepEqual result.errs, [
                {path:'a', msg: "Value '3' at 'a' not allowed"}
            ]
        .then -> conn.findOne('test', {_id:1})
        .then (doc) ->
            assert.equal doc.a, 1
            done()
        .catch (err) -> done(err)

    it 'does not update simple item when an unique error exists', (done) ->
        env.endpoint = new Endpoint {
            a:
                a:
                    type: Integer
                    unique: true
        }
        data = {_id:2,a:{a:4}}
        conn.insert('test', data)
        .then ->
            conn.insert('test', {_id:1,a:{a:3}})
        .then ->
            data.a.a = 3
        .then -> updateItem(env, data)
        .then (result) ->
            assert.equal result.errs.length, 1
            assert.deepEqual result.errs, [
                {path:'a.a', msg: "Value '3' at 'a.a' is not unique"}
            ]
        .then -> conn.findOne('test', {_id:2})
        .then (doc) ->
            assert.equal doc.a.a, 4
            done()
        .catch (err) -> done(err)
        

    it 'adds update history for single item', (done) ->
        env.endpoint = new Endpoint {
            a: Integer
        }
        data = {_id:1,a:1}
        conn.insert('test', data)
        .then -> data.a = 2
        .then -> updateItem(env, data)
        .then (result) ->
            assert.property result, 'tid'
            assert.property result, 'mongoResponse'
            assert.deepEqual result.doc, {
                    _id:1
                    a:2
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


    it 'handles nulls for all data types', (done) ->
        t = schema.types
        env.endpoint = new Endpoint {
            a: t.String
            b: t.Integer
            c: t.Float
            d: t.Boolean
            e: t.Date
            f:
                type: t.Reference
                collection: 'test'
        }
        data = {_id:1, a:1, b:1, c:1, d:1, e:1, f:1}
        conn.insert('test', data)
        .then ->
            data = {_id:1, a:null, b:null, c:null, d:null, e:null, f:null}
        .then -> updateItem(env, data)
        .then (result) ->
            assert.property result, 'tid'
            assert.property result, 'mongoResponse'
            assert.deepEqual result.doc,
                {_id:1, a:null, b:null, c:null, d:null, e:null, f:null}
            done()
        .catch (err) -> done(err)
