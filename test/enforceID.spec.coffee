assert = require('chai').assert
schema = require('../src/api/schema')
Schema = schema.Schema
Endpoint = schema.Endpoint

types =  schema.types
Integer = types.Integer
List = types.List
Doc = types.Doc
Auto = types.Auto
AutoInit = types.AutoInit

enforceID = require('../src/api/viewFunctions/enforceID')
p = console.log


describe 'enforceID function', ->
        
    it 'does nothing to simple new objects', ->
        data = {
            a: 1
            b: 1
            c: 1
        }
        endp = new Endpoint {
            a: Integer
        }
        enforceID(data, endp)
        assert.deepEqual data, {
            __proto__: data.__proto__
            a:1
            b:1
            c:1
        }
        
    it 'does nothing to simple existing objects', ->
        data = {
            _id:4
            a: 1
            b: 1
            c: 1
        }
        endp = new Endpoint {
            a: Integer
        }
        enforceID(data, endp)
        assert.deepEqual data, {
            __proto__: data.__proto__
            _id:4
            a: 1
            b: 1
            c: 1
        }
        
    it 'handles nested objects', ->
        data = {
            _id:4
            a: 
                b: 1
                c: 1
                d:
                    e:1                    
        }
        endp = new Endpoint {
            a:
                b: Integer
                c: Integer
                d:
                    e:Integer                    
        }
        enforceID(data, endp)
        assert.deepEqual data, {
            __proto__: data.__proto__
            _id:4
            a:
                _id: 1
                b: 1
                c: 1
                d:
                    _id: 1
                    e:1                    
        }
    
    it 'handles lists of objects', ->
        data = {
            _id:4
            a: [{
                b: 1
                c: 1
                d:
                    e:1
            },{
                _id:2
                b: 2
                c: 2
                d:
                    e:2
            }]
        }
        endp = new Endpoint {
            a: [
                b: Integer
                c: Integer
                d:
                    e:Integer
            ]
        }
        enforceID(data, endp)
        assert.deepEqual data, {
            __proto__: data.__proto__
            _id:4
            a: [{
                _id:3
                b: 1
                c: 1
                d:
                    _id:1
                    e:1
            },{
                _id:2
                b: 2
                c: 2
                d:
                    _id:1
                    e:2
            }]                   
        }

    it 'handles lists of objects with lists', ->
        data = {
            _id:4
            a: [
                {b: [{c: 1, d:{e:1}}, {c: 1, d:{e:1}}]}
                {b: [{c: 2, d:{e:2}}, {_id:2, c: 2, d:{e:2}}]}
            ]
        }
        endp = new Endpoint {
            a: [
                b: [
                    c: Integer
                    d:
                        e:Integer
                ]
            ]
        }
        enforceID(data, endp)
        assert.deepEqual data, {
            __proto__: data.__proto__
            _id:4
            a: [
                {_id:1, b: [{_id:1, c: 1, d:{_id:1, e:1}}, {_id:2, c: 1, d:{_id:1, e:1}}]}
                {_id:2, b: [{_id:3, c: 2, d:{_id:1, e:2}}, {_id:2, c: 2, d:{_id:1, e:2}}]}
            ]
        }

    it 'handles three levels of lists', ->
        data = {
            _id:4
            a: [
                b: [
                    c: [
                        d:1
                    ]
                ]
            ]
        }
        endp = new Endpoint {
            a: [
                b: [
                    c: [
                        d: Integer
                    ]
                ]
            ]
        }
        enforceID(data, endp)
        assert.deepEqual data, {
            __proto__: data.__proto__
            _id:4
            a: [
                _id:1
                b: [
                    _id:1
                    c: [
                        _id:1
                        d:1
                    ]
                ]
            ]
        }
