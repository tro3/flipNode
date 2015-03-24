assert = require('chai').assert
Doc = require('../src/doc').Doc
schema = require('../src/schema')
Schema = schema.Schema
Endpoint = schema.Endpoint

types =  schema.types
Integer = types.Integer
List = types.List
Dict = types.Dict
Auto = types.Auto
AutoInit = types.AutoInit

enforceID = require('../src/viewFunctions/enforceID')
p = console.log


describe.only 'enforceID function', ->
        
    it 'does nothing to simple new objects', ->
        data = new Doc {
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
        data = new Doc {
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
        
    it 'handles nested objects'
    
    it 'handles lists of objects'
