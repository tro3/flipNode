assert = require('chai').assert
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


enforceTypes = require('../src/api/schemaFunctions/enforceSchema/enforceTypes')
p = console.log


xdescribe 'enforceTypes function', ->
    it 'handles simple objects', ->
        endp =
            schema:
                new Schema {
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
        result = enforceTypes({endpoint:endp, doc:data, errs:[]})
        p result.errs
        assert.equal result.errs.length, 0
        assert.deepEqual result.doc, {
            int:1
            str: '2'
            flt: 1.2
            date: new Date('1/1/2001')
            bool: false
            ref: 5
        }

    it 'handles nested objects', ->
        endp =
            schema: new Schema {
                a:
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
            a:
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
        result = enforceTypes({endpoint:endp, doc:data, errs:[]})
        assert.equal result.errs.length, 0
        assert.deepEqual result.doc, {
            a:
                int:1
                str: '2'
                flt: 1.2
                date: new Date('1/1/2001')
                bool: false
                ref: 5
        }

    it 'handles lists of primitives', ->
        endp =
            schema: new Schema {
                a:[Integer]
            }
        data =
            a: ['1',2,'3.3']
        result = enforceTypes({endpoint:endp, doc:data, errs:[]})
        assert.equal result.errs.length, 0
        assert.deepEqual result.doc, {
            a: [1,2,3]
        }

    it 'handles lists of objects', ->
        endp =
            schema: new Schema {
                a:[
                    int: Integer
                    str: String
                    flt: Float
                    date:  Date
                    bool: Boolean
                    ref: Reference
                    auto: Auto
                    autoi: AutoInit
                ]
            }
        data =
            a: [
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
        ]
        result = enforceTypes({endpoint:endp, doc:data, errs:[]})
        assert.equal result.errs.length, 0
        assert.deepEqual result.doc, {
            a: [
                int:1
                str: '2'
                flt: 1.2
                date: new Date('1/1/2001')
                bool: false
                ref: 5
            ]
        }

    it 'handles nested lists of primitives', ->
        endp =
            schema: new Schema {
                b:
                    a:[Reference]
            }
        data =
            b:
                a: [{_id:1},{_id:'2', name:'fred'}]
        result = enforceTypes({endpoint:endp, doc:data, errs:[]})
        assert.equal result.errs.length, 0
        assert.deepEqual result.doc, {
            b:
                a: [1,2]
        }

    it 'handles nested lists of objects', ->
        endp =
            schema: new Schema {
                b:
                    a:[
                        int: Integer
                        str: String
                        flt: Float
                        date:  Date
                        bool: Boolean
                        ref: Reference
                        auto: Auto
                        autoi: AutoInit
                    ]
            }
        data =
            b:
                a: [
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
        ]
        result = enforceTypes({endpoint:endp, doc:data, errs:[]})
        assert.equal result.errs.length, 0
        assert.deepEqual result.doc, {
            b:
                a: [
                    int:1
                    str: '2'
                    flt: 1.2
                    date: new Date('1/1/2001')
                    bool: false
                    ref: 5
                ]
        }

    it 'handles extraneous data', ->
        endp =
            schema: new Schema {
                b:
                    a:[
                        int: Integer
                        str: String
                        flt: Float
                        date:  Date
                        bool: Boolean
                        ref: Reference
                        auto: Auto
                        autoi: AutoInit
                    ]
            }
        data =
            c: 1
            d:
                e: 1
            f:
                g: 1
            b:
                name: 234
                obj:
                    name: 1
                a: [
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
                    ghj: [
                        'fgh'
                    ]
        ]
        result = enforceTypes({endpoint:endp, doc:data, errs:[]})
        assert.equal result.errs.length, 0
        assert.deepEqual result.doc, {
            b:
                a: [
                    int:1
                    str: '2'
                    flt: 1.2
                    date: new Date('1/1/2001')
                    bool: false
                    ref: 5
                ]
        }

    it 'handles errors', ->
        endp =
            schema: new Schema {
                int: Integer
                list: [Integer]
                doc:
                    int: Float
                    list: [Float]                
                doclist: [
                    int: Reference
                    list: [Reference]
                    doclist: [
                        int: Date
                        list: [Date]                    
                    ]
                ]
            }
        data =
            int: 'q'
            list: [1,2,'y']
            doc:
                int: 'ui'
                list: [1.2,'2.4','ui']                
            doclist: [
                int: {_id:'h'}
                list: [{_id:1, name:'h'}, {name:'j'}]
                doclist: [
                    int: 'ert'
                    list: ['2/2/2002', '2005-01-01T00:00:00', 'I am the model of a modern...']                    
                ]
            ]
        result = enforceTypes({endpoint:endp, doc:data, errs:[]})
        assert.equal result.errs.length, 8
        assert.deepEqual result.doc, {
            int: null
            list: [1,2,null]
            doc:
                int: null
                list: [1.2,2.4,null]                
            doclist: [
                int: null
                list: [1, null]
                doclist: [
                    int: null
                    list: [
                        new Date('2/2/2002')
                        new Date('2005-01-01T00:00:00')
                        null
                    ]                    
                ]
            ]
        }
        assert.sameMembers (x.path for x in result.errs), [
            'int'
            'list.2'
            'doc.int'
            'doc.list.2'
            'doclist.0.int'
            'doclist.0.list.1'
            'doclist.0.doclist.0.int'
            'doclist.0.doclist.0.list.2'
        ]
