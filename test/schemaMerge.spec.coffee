assert = require('chai').assert

schema = require('../src/api/schema')
Schema = schema.Schema
Endpoint = schema.Endpoint

types =  schema.types
Integer = types.Integer
List = types.List
Doc = types.Doc

schemaMerge = require('../src/api/schemaFunctions/schemaMerge')
p = console.log


xdescribe 'schemaMerge function', ->
        
    it 'handles simple objects', ->
        old =
            _id:1
            a:1
            b:2
        new_ =
            _id:1
            a:2
            c:3
        endp =
            schema: new Schema {
                a: Integer
                b: Integer
                c: Integer
            }
        assert.deepEqual schemaMerge(endp, old, new_), {
            _id:1
            a:2
            b:2
            c:3
        }
        
    it 'handles nested objects', ->
        old =
            _id:1
            a:
                _id:1
                b:2
                c:3
            d:1
            e:
                _id:1
                f:1
        new_ =
            _id:1
            a:
                _id:1
                b:3
                d:1
            g:
                h:1
        endp = new Endpoint {
            a:
                b: Integer
                c: Integer
                d: Integer
                e: Integer
            g:
                h: Integer
            j:
                k: Integer
        }
        assert.deepEqual schemaMerge(endp, old, new_), {
            _id:1
            a:
                _id:1
                b:3
                c:3
                d:1
                e:null
            g:
                _id:null
                h:1
            j:
                _id:null
                k: null
        }
        
    it 'handles simple lists', ->
        old =
            _id:1
            a:
                _id:1
                a:[1,2]
                c:[1]
        new_ =
            _id:1
            a:
                _id:1
                a:[1,2,3]
                b:[1,2]
        endp = new Endpoint {
                a:
                    a: [Integer]
                    b: [Integer]
                    c: [Integer]
                    d: [Integer]
            }
        assert.deepEqual schemaMerge(endp, old, new_), {
            _id:1
            a:
                _id:1
                a:[1,2,3]
                b:[1,2]
                c:[1]
                d:[]
        }

    it 'handles lists of objects', ->
        old =
            _id:1
            a: [{_id:1, a:1, b:2},
                {_id:2, c:3}
                ]
        new_ =
            _id:1
            a: [{_id:1, a:2},
                {_id:2, b:1}
                ]
        endp =
            schema: new Schema {
                a: [
                    a: Integer
                    b: Integer
                ]
            }
        assert.deepEqual schemaMerge(endp, old, new_), {
            _id:1
            a: [{_id:1, a:2, b:2},
                {_id:2, a:null, b:1}
                ]
        }
        
    it 'handles adding of objects in list', ->
        old =
            _id:1
            a: [{
                _id:1
                a:1
                b:2
            }]
        new_ =
            _id:1
            a: [{
                _id:1
                a:1
                b:2
            },{
                b:1
            }]
        endp =
            schema: new Schema {
                a: [
                    a: Integer
                    b: Integer
                ]
            }
        assert.deepEqual schemaMerge(endp, old, new_), {
            _id:1
            a: [{
                _id:1
                a:1
                b:2
            },{
                _id:null
                a:null
                b:1
            }]
        }

    it 'handles dropping of objects in list', ->
        old =
            _id:1
            a: [{
                _id:1
                a:1
                b:2
            },{
                _id:2
                a:2
                b:1
            }]
        new_ =
            _id:1
            a: [{
                _id:2
                a:1
            }]
        endp =
            schema: new Schema {
                a: [
                    a: Integer
                    b: Integer
                ]
            }
        assert.deepEqual schemaMerge(endp, old, new_), {
            _id:1
            a: [{
                _id:2
                a:1
                b:1
            }]
        }
        
    it 'handles reordering of objects in list', ->
        old =
            _id:1
            a: [{
                _id:1
                a:1
                b:2
            },{
                _id:2
                a:2
                b:1
            }]
        new_ =
            _id:1
            a: [{_id:2},{_id:1}]
        endp =
            schema: new Schema {
                a: [
                    a: Integer
                    b: Integer
                ]
            }
        assert.deepEqual schemaMerge(endp, old, new_), {
            _id:1
            a: [{
                _id:2
                a:2
                b:1
            },{
                _id:1
                a:1
                b:2
            }]
        }

    it 'handles other new data in place of object', ->
        old =
            _id:1
            a: 1
            b:
                c:1
        new_ =
            _id:1
            a:
                c:1
            b: 1
        endp =
            schema: new Schema {
                a: 
                    c: Integer
                b: Integer
            }
        assert.deepEqual schemaMerge(endp, old, new_), {
            _id:1
            a:
                _id: null
                c:1
            b: 1
        }
    
    it 'handles other new data in place of array', ->
        old =
            _id:1
            a: 1
            b: [1,2]
            c: [{_id:1,a:1}]
            d: 1
        new_ =
            _id:1
            a: [1,2]
            b: 1
            c: 1
            d: [{_id:1,a:1}]
        endp =
            schema: new Schema {
                a: [Integer]
                b: Integer
                c: Integer
                d: [
                    a: Integer
                ]
            }
        assert.deepEqual schemaMerge(endp, old, new_), {
            _id:1
            a: [1,2]
            b: 1
            c: 1
            d: [{_id:1,a:1}]
        }
    