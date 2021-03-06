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


enforceAllowed = require('../src/api/schemaFunctions/enforceSchema/enforceAllowed')
p = console.log



describe 'enforceAllowed function', ->
  
  it 'handles simple objects', ->
    endp = new Endpoint {
      a:
        type: Integer
        allowed: [1,2]
      b:
        type: Integer
        allowed: (el) -> [2,3]
    }
    data = {a:3, b:2}
    result = enforceAllowed({endpoint:endp, doc:data, errs:[]})
    assert.equal result.errs.length, 1
    assert.sameMembers (x.path for x in result.errs), [
      'a'
    ]
    data = {a:1, b:1}
    result = enforceAllowed({endpoint:endp, doc:data, errs:[]})
    assert.equal result.errs.length, 1
    assert.sameMembers (x.path for x in result.errs), [
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
    data = {a: {b: [
      {d:[{e:2}]}
      {c:2, d:[]}
      {c:1,d:[{e:1, f:1}]}
      {c:null,d:[]}
    ]}}
    result = enforceAllowed({endpoint:endp, doc:data, errs:[]})
    assert.equal result.errs.length, 2
    assert.sameMembers (x.path for x in result.errs), [
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
    data = {a: {b: [
      {allowed:[1,3],c:2}
      {allowed:[1,3],c:3}
    ]}}
    result = enforceAllowed({endpoint:endp, doc:data, errs:[]})
    assert.equal result.errs.length, 1
    assert.sameMembers (x.path for x in result.errs), [
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
    data = {allowed:[1,3], a: {b: [
      {c:2}
      {c:3}
    ]}}
    result = enforceAllowed({endpoint:endp, doc:data, errs:[]})
    assert.equal result.errs.length, 1
    assert.sameMembers (x.path for x in result.errs), [
      'a.b.0.c'
    ]

  it 'handles env dependence', ->
    endp = new Endpoint {
      allowed: [Integer]
      a:
        b: [
          c:
            type: Integer
            allowed: (el, root, env) -> env.allowed
        ]
    }
    data = {a: {b: [
      {c:2}
      {c:3}
    ]}}
    result = enforceAllowed({endpoint:endp, doc:data, errs:[], allowed:[1,3]})
    assert.equal result.errs.length, 1
    assert.sameMembers (x.path for x in result.errs), [
      'a.b.0.c'
    ]

