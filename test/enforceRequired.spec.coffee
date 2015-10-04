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


enforceRequired = require('../src/api/schemaFunctions/enforceSchema/enforceRequired')
p = console.log


describe 'enforceRequired function', ->
    
    it 'handles simple objects', ->
        endp = new Endpoint {
            a:
                type: Integer
                required: true
            b: Integer
        }
        data = {b:1}
        result = enforceRequired(endp)(data)
        assert.equal result.errs.length, 1
        assert.sameMembers (x.path for x in result.errs), [
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
        data = {a: {a: null, b:1}}
        result = enforceRequired(endp)(data)
        assert.equal result.errs.length, 1
        assert.sameMembers (x.path for x in result.errs), [
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
        data = {a: {b: [
            {c:'',d:[{e:'a'}]}
            {d:[]}
            {c:1,d:[{e:' ', f:1}]}
            {c:null,d:[]}
        ]}}
        result = enforceRequired(endp)(data)
        assert.equal result.errs.length, 4
        assert.sameMembers (x.path for x in result.errs), [
            'a.b.0.c'
            'a.b.1.c'
            'a.b.2.d.0.e'
            'a.b.3.c'
        ]

