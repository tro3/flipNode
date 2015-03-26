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


incoming = require('../src/viewFunctions/incoming')
p = console.log


describe.only 'incoming function', ->
    it 'handles simple objects', ->
        sch = new Schema {
            int: Integer
            str: String
            flt: Float
            date:  Date
            bool: Boolean
            ref: Reference
            auto: Auto
            autoi: AutoInit
        }
        data =
            int: '1'
            str: 2
            flt: '1.2'
            date: '1/1/2001'
            bool: 0
            ref:
                _id:5
                name: 'fred'
            auto: 1
            autoi: 1
        incoming(data, sch)
        assert.deepEqual data, {
            int:1
            str: '2'
            flt: 1.2
            date: new Date('1/1/2001')
            bool: false
            ref: 5
        }
