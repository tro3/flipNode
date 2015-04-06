assert = require('chai').assert
schema = require('../src/api/schema')
Schema = schema.Schema
Endpoint = schema.Endpoint

types =  schema.types
Integer = types.Integer
List = types.List
Dict = types.Dict
Auto = types.Auto
AutoInit = types.AutoInit

runAuto = require('../src/api/viewFunctions/auto').runAuto
p = console.log


describe 'runAuto function', ->
        
    it 'handles simple new objects', ->
        data = {
            a: 1
            b: 1
            c: 1
        }
        endp = new Endpoint {
            a: Integer
            b:
                type: Auto
                auto: (el) -> el.a+1
            c:
                type: AutoInit
                auto: (el) -> el.a+1 
        }
        runAuto(data, endp)
        assert.deepEqual data, {
            __proto__: data.__proto__
            a:1
            b:2
            c:2
        }
        
    it 'handles simple existing objects', ->
        data = {
            _id: 1
            a: 1
            b: 1
            c: 1
        }
        endp = new Endpoint {
            a: Integer
            b:
                type: Auto
                auto: (el) -> el.a+1
            c:
                type: AutoInit
                auto: (el) -> el.a+1 
        }
        runAuto(data, endp)
        assert.deepEqual data, {
            __proto__: data.__proto__
            _id: 1
            a:1
            b:2
            c:1
        }

    it 'handles nested objects', ->
        data = {
            _id: 1
            n1:
                a: 1
                b: 1
                c: 1
            n2:
                _id: 1
                a: 1
                b: 1
                c: 1
        }
        endp = new Endpoint {
            n1:
                a: Integer
                b:
                    type: Auto
                    auto: (el) -> el.a+1
                c:
                    type: AutoInit
                    auto: (el) -> el.a+1 
            n2:
                a: Integer
                b:
                    type: Auto
                    auto: (el) -> el.a+1
                c:
                    type: AutoInit
                    auto: (el) -> el.a+1 
        }
        runAuto(data, endp)
        assert.deepEqual data, {
            __proto__: data.__proto__
            _id: 1
            n1:
                a: 1
                b: 2
                c: 2
            n2:
                _id: 1
                a: 1
                b: 2
                c: 1
        }

    it 'handles lists of objects', ->
        data = {
            a: [
              {_id:1, a:2, b:1, c:1}    
              {a:2, b:1, c:1}    
            ]
        }
        endp = new Endpoint {
            a: [
                a: Integer
                b:
                    type: Auto
                    auto: (el) -> el.a+1
                c:
                    type: AutoInit
                    auto: (el) -> el.a+1
            ]
        }
        runAuto(data, endp)
        assert.deepEqual data, {
            __proto__: data.__proto__
            a: [
              {_id:1, a:2, b:3, c:1}    
              {a:2, b:3, c:3}    
            ]
        }

    it 'handles nested objects referencing root', ->
        data = {
            _id: 1
            f: 2
            n1:
                a: 1
                b: 1
                c: 1
            n2:
                _id: 1
                a: 1
                b: 1
                c: 1
        }
        endp = new Endpoint {
            n1:
                a: Integer
                b:
                    type: Auto
                    auto: (el, root) -> root.f+1
                c:
                    type: AutoInit
                    auto: (el, root) -> root.f+1 
            n2:
                a: Integer
                b:
                    type: Auto
                    auto: (el, root) -> root.f+1
                c:
                    type: AutoInit
                    auto: (el, root) -> root.f+1
        }
        runAuto(data, endp)
        assert.deepEqual data, {
            __proto__: data.__proto__
            _id: 1
            f: 2
            n1:
                a: 1
                b: 3
                c: 3
            n2:
                _id: 1
                a: 1
                b: 3
                c: 1
        }

    it 'handles lists of objects referencing root', ->
        data = {
            f: 3
            a: [
              {_id:1, a:1, b:1, c:1}    
              {a:1, b:1, c:1}    
            ]
        }
        endp = new Endpoint {
            f: Integer
            a: [
                a: Integer
                b:
                    type: Auto
                    auto: (el, root) -> root.f+1
                c:
                    type: AutoInit
                    auto: (el, root) -> root.f+1
            ]
        }
        runAuto(data, endp)
        assert.deepEqual data, {
            __proto__: data.__proto__
            f: 3
            a: [
              {_id:1, a:1, b:4, c:1}    
              {a:1, b:4, c:4}    
            ]
        }

    it 'handles nested objects referencing req', ->
        req =
            f: 5
        data = {
            _id: 1
            n1:
                a: 1
                b: 1
                c: 1
            n2:
                _id: 1
                a: 1
                b: 1
                c: 1
        }
        endp = new Endpoint {
            n1:
                a: Integer
                b:
                    type: Auto
                    auto: (el, root, req) -> req.f+1
                c:
                    type: AutoInit
                    auto: (el, root, req) -> req.f+1 
            n2:
                a: Integer
                b:
                    type: Auto
                    auto: (el, root, req) -> req.f+1
                c:
                    type: AutoInit
                    auto: (el, root, req) -> req.f+1
        }
        runAuto(data, endp, req)
        assert.deepEqual data, {
            __proto__: data.__proto__
            _id: 1
            n1:
                a: 1
                b: 6
                c: 6
            n2:
                _id: 1
                a: 1
                b: 6
                c: 1
        }

    it 'handles lists of objects referencing req', ->
        req =
            f: 5        
        data = {
            a: [
              {_id:1, a:1, b:1, c:1}    
              {a:1, b:1, c:1}    
            ]
        }
        endp = new Endpoint {
            f: Integer
            a: [
                a: Integer
                b:
                    type: Auto
                    auto: (el, root, req) -> req.f+1
                c:
                    type: AutoInit
                    auto: (el, root, req) -> req.f+1
            ]
        }
        runAuto(data, endp, req)
        assert.deepEqual data, {
            __proto__: data.__proto__
            a: [
              {_id:1, a:1, b:6, c:1}    
              {a:1, b:6, c:6}    
            ]
        }