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


describe.only 'behavior module', ->

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
                                type: String
                                required: true                            
                        ]
                    ]
            }
            data = new Doc {a: {b: [
                {c:'',d:[{e:'a'}]}
                {d:[]}
                {c:1,d:[{e:' ', f:1}]}
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


    describe 'allowed function', ->
        
        it 'handles simple objects', ->
            endp = new Endpoint {
                a:
                    type: Integer
                    allowed: [1,2]
                b:
                    type: Integer
                    allowed: (el) -> [2,3]
            }
            data = new Doc {a:3, b:2}
            errs = behavior.allowed(data, endp)
            assert.equal errs.length, 1
            assert.sameMembers (x.path for x in errs), [
                'a'
            ]
            data = new Doc {a:1, b:1}
            errs = behavior.allowed(data, endp)
            assert.equal errs.length, 1
            assert.sameMembers (x.path for x in errs), [
                'b'
            ]

        it 'handles nested lists of objects', ->
            endp = new Endpoint {
                a:
                    b: [
                        c:
                            type: Integer
                            allowed: (el) -> [2,3]
                        d: [
                            e:
                                type: String
                                allowed: (el) -> [2,3]                        
                        ]
                    ]
            }
            data = new Doc {a: {b: [
                {d:[{e:2}]}
                {c:2, d:[]}
                {c:1,d:[{e:1, f:1}]}
                {c:null,d:[]}
            ]}}
            errs = behavior.allowed(data, endp)
            assert.equal errs.length, 2
            assert.sameMembers (x.path for x in errs), [
                'a.b.2.c'
                'a.b.2.d.0.e'
            ]


        it 'handles element dependence', ->
            endp = new Endpoint {
                a:
                    b: [
                        allowed: [Integer]
                        c:
                            type: Integer
                            allowed: (el) -> el.allowed
                    ]
            }
            data = new Doc {a: {b: [
                {allowed:[1,3],c:2}
                {allowed:[1,3],c:3}
            ]}}
            errs = behavior.allowed(data, endp)
            assert.equal errs.length, 1
            assert.sameMembers (x.path for x in errs), [
                'a.b.0.c'
            ]

        it 'handles root dependence', ->
            endp = new Endpoint {
                allowed: [Integer]
                a:
                    b: [
                        c:
                            type: Integer
                            allowed: (el, root) -> root.allowed
                    ]
            }
            data = new Doc {allowed:[1,3], a: {b: [
                {c:2}
                {c:3}
            ]}}
            errs = behavior.allowed(data, endp)
            assert.equal errs.length, 1
            assert.sameMembers (x.path for x in errs), [
                'a.b.0.c'
            ]

        it 'handles req dependence', ->
            endp = new Endpoint {
                allowed: [Integer]
                a:
                    b: [
                        c:
                            type: Integer
                            allowed: (el, root, req) -> req.allowed
                    ]
            }
            req =
                allowed: [1,3]
            data = new Doc {a: {b: [
                {c:2}
                {c:3}
            ]}}
            errs = behavior.allowed(data, endp, req)
            assert.equal errs.length, 1
            assert.sameMembers (x.path for x in errs), [
                'a.b.0.c'
            ]

    describe 'unique function', ->
        
        it 'handles simple objects'