assert = require('chai').assert
Doc = require('../src/doc').Doc
schema = require('../src/schema')
Schema = schema.Schema
Endpoint = schema.Endpoint

types =  schema.types
List = types.List
Dict = types.Dict
String = types.String
Integer = types.Integer
Float = types.Float
Date = types.Date
Boolean = types.Boolean
Reference = types.Reference
Auto = types.Auto
AutoInit = types.AutoInit


behavior = require('../src/viewFunctions/behavior')
p = console.log


describe 'behavior module', ->

    describe 'required function', ->
        
        it 'handles simple objects', ->
            endp = new Endpoint {
                a:
                    type: Integer
                    required: true
                b: Integer
            }
            data = new Doc {b:1}
            errs = behavior.required(data, endp)
            assert.equal errs.length, 1
            assert.sameMembers (x.path for x in errs), [
                'a'
            ]
                
        it 'handles nested objects', ->
            endp = new Endpoint {
                a:
                    a:
                        type: Integer
                        required: true
                    b: Integer
            }
            data = new Doc {a: {a: null, b:1}}
            errs = behavior.required(data, endp)
            assert.equal errs.length, 1
            assert.sameMembers (x.path for x in errs), [
                'a.a'
            ]


        it 'handles nested lists of objects', ->
            endp = new Endpoint {
                a:
                    b: [
                        c:
                            type: Integer
                            required: true
                        d: [
                            e:
                                type: Integer
                                required: true                            
                        ]
                    ]
            }
            data = new Doc {a: {b: [
                {c:'',d:[{e:1}]}
                {d:[]}
                {c:1,d:[{f:1}]}
                {c:null,d:[]}
            ]}}
            errs = behavior.required(data, endp)
            assert.equal errs.length, 4
            assert.sameMembers (x.path for x in errs), [
                'a.b.0.c'
                'a.b.1.c'
                'a.b.2.d.0.e'
                'a.b.3.c'
            ]
