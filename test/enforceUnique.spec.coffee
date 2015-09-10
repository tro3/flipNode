assert = require('chai').assert
sinon = require('sinon')

connect = require('../src/api/db/qdb')
DbCache = require('../src/api/db/dbCache')
schema = require('../src/api/schema')
Schema = schema.Schema
Endpoint = schema.Endpoint

types =  schema.types
List = types.List
Doc = types.Doc
String = types.String
Integer = types.Integer
Float = types.Float
Date = types.Date
Boolean = types.Boolean
Reference = types.Reference
Auto = types.Auto
AutoInit = types.AutoInit


enforceUnique = require('../src/api/schemaFunctions/enforceUnique')
p = console.log


describe 'enforceUnique function', ->
    conn = null
    req = {}
    spy = null

    before ->
        conn = connect('mongodb://localhost:27017/test')
        conn.insert('items', [
            {_id:1, name: 'Bob', address: {city: 'Palo Alto'}}
            {_id:2, name: 'Fred', address: {city: 'Menlo Park'}}
        ])
        spy = sinon.spy(conn, 'findOne')

    after (done) ->
        conn.drop('items')
        .then -> conn.close()
        .then -> done()

    beforeEach ->
        req.cache = new DbCache(conn)

    
    it 'handles top-level contraints', (done) ->
        req.collection = 'items'
        req.endpoint = endp = new Endpoint {
            name:
                type: String
                unique: true
            address:
                city:
                    type: String
                    unique: true
        }
        data = {name: 'Bob', address: {city: 'San Diego'}}
        enforceUnique(endp)(data, req)
        .then (result) ->
            assert.equal result.errs.length, 1
            assert.sameMembers (x.path for x in result.errs), [
                'name'
            ]
            done()
        .catch (err) -> done(err)

    it 'handles nested contraints', (done) ->
        req.collection = 'items'
        req.endpoint = endp = new Endpoint {
            name:
                type: String
                unique: true
            address:
                city:
                    type: String
                    unique: true
        }
        data = {name: 'Robert', address: {city: 'Palo Alto'}}
        enforceUnique(endp)(data, req)
        .then (result) ->
            assert.equal result.errs.length, 1
            assert.sameMembers (x.path for x in result.errs), [
                'address.city'
            ]
            done()
        .catch (err) -> done(err)