assert = require('chai').assert
utils = require './lib/utils'
p = console.log

schema = require('../src/api/schema')

Schema = schema.Schema
Endpoint = schema.Endpoint
expand = schema.expand
paths = schema.paths
prototype = schema.prototype


types =  schema.types
String = types.String
Integer = types.Integer
Reference = types.Reference
List = types.List
Doc = types.Doc
Auto = types.Auto
AutoInit = types.AutoInit


describe 'Schema module', ->

    describe 'expand function', ->
        it 'handles simple types', ->
            cfg =
                name: types.String
            utils.assertEqualObj expand(cfg), {
                _id:
                    type: types.Id
                name:
                    type: types.String
            }

        it 'handles complex types', ->
            cfg =
                name:
                    type: types.String
                    required: true
            utils.assertEqualObj expand(cfg), {
                _id:
                    type: types.Id
                name:
                    type: types.String
                    required: true
            }

        it 'handles simple subdocs', ->
            cfg =
                address:
                    street: types.String
                    city: types.String
            utils.assertEqualObj expand(cfg), {
                _id:
                    type: types.Id
                address:
                    type: types.Doc
                    schema:
                        _id:
                            type: types.Id
                        street:
                            type: types.String
                        city:
                            type: types.String
            }

        it 'handles complex subdocs', ->
            cfg =
                address:
                    type: types.Doc
                    schema:
                        street: types.String
                        city: types.String
            utils.assertEqualObj expand(cfg), {
                _id:
                    type: types.Id
                address:
                    type: types.Doc
                    schema:
                        _id:
                            type: types.Id
                        street:
                            type: types.String
                        city:
                            type: types.String
            }

        it 'handles simple lists', ->
            cfg =
                tags: [types.String]
            utils.assertEqualObj expand(cfg), {
                _id:
                    type: types.Id
                tags:
                    type: types.List
                    subtype:
                        type: types.String
            }

        it 'handles complex lists', ->
            cfg =
                tags:
                    type: types.List
                    subtype: types.String
            utils.assertEqualObj expand(cfg), {
                _id:
                    type: types.Id
                tags:
                    type: types.List
                    subtype:
                        type: types.String
            }

        it 'handles simple lists of objects', ->
            cfg =
                address: [
                    street: types.String
                    city: types.String
                ]
            utils.assertEqualObj expand(cfg), {
                _id:
                    type: types.Id
                address:
                    type: types.List
                    schema:
                        _id:
                            type: types.Id
                        street:
                            type: types.String
                        city:
                            type: types.String
            }

        it 'handles complex lists of objects', ->
            cfg =
                address:
                    type: types.List
                    schema:
                        street:
                            type: types.String
                        city:
                            type: types.String
            utils.assertEqualObj expand(cfg), {
                _id:
                    type: types.Id
                address:
                    type: types.List
                    schema:
                        _id:
                            type: types.Id
                        street:
                            type: types.String
                        city:
                            type: types.String
            }

        it 'handles nested objects and lists', ->
            cfg =
                subdoc:
                    subdoclist: [
                        name: types.String
                    ]
                sublist: [
                    subdoc:
                        address: types.String
                ]
            utils.assertEqualObj expand(cfg), {
                _id:
                    type: types.Id
                subdoc:
                    type: types.Doc
                    schema:
                        _id:
                            type: types.Id
                        subdoclist:
                            type: types.List
                            schema:
                                _id:
                                    type: types.Id
                                name:
                                    type:types.String
                sublist:
                    type: types.List
                    schema:
                        _id:
                            type: types.Id
                        subdoc:
                            type: types.Doc
                            schema:
                                _id:
                                    type: types.Id
                                address:
                                    type: types.String
            }

    describe 'Schema object', ->
        describe 'get function', ->
            beforeEach ->
                @sch = new Schema(
                    simple1: types.String
                    simple2:
                        type: types.String
                        required: true
                    sub: {
                        simple1: types.String
                        simple2:
                            type: types.String
                            required: true
                    }
                    list1: [types.String]
                    list2: [
                        type: types.String
                        auth:
                            read: true
                    ]
                    doclist1: [
                        simple1: types.String
                        simple2:
                            type: types.String
                            required: true
                    ]
                    doclist2:
                        type: types.List
                        schema:
                            simple1: types.String
                            simple2:
                                type: types.String
                                required: true
                    nested:
                        simple: types.String
                        list: [types.String]
                        doclist: [
                            simple:
                                type: types.String
                                required: true
                        ]
                        doc:
                            simple:
                                type: types.String
                                required: true
                            list: [
                                type: types.String
                                auth:
                                    read: true
                            ]
                            doclist:
                                type: types.List
                                schema:
                                    simple1: types.String
                                    simple2:
                                        type: types.String
                                        required: true
                )

            it 'handles simple types', ->
                utils.assertEqualObj @sch.get('simple1'), {
                    type: types.String
                }
                utils.assertEqualObj @sch.get('simple2'), {
                    type: types.String
                    required: true
                }
                
            it 'handles subdocs', ->
                utils.assertEqualObj @sch.get('sub.simple1'), {
                    type: types.String
                }
                utils.assertEqualObj @sch.get('sub.simple2'), {
                    type: types.String
                    required: true
                }                
                
            it 'handles simple lists', ->
                utils.assertEqualObj @sch.get('list1'), {
                    type: types.List
                    subtype:
                        type: types.String
                }
                utils.assertEqualObj @sch.get('list2'), {
                    type: types.List
                    subtype:
                        type: types.String
                        auth:
                            read: true
                }                

            it 'handles lists of docs', ->
                utils.assertEqualObj @sch.get('doclist1.simple1'), {
                    type: types.String
                }
                utils.assertEqualObj @sch.get('doclist2.1.simple2'), {
                    type: types.String
                    required: true
                }               
            
            it 'handles nested docs and lists', ->
                utils.assertEqualObj @sch.get('nested.simple'), {
                    type: types.String
                }
                utils.assertEqualObj @sch.get('nested.list'), {
                    type: types.List
                    subtype:
                        type: types.String
                }
                utils.assertEqualObj @sch.get('nested.doclist.simple'), {
                    type: types.String
                    required: true
                }
                utils.assertEqualObj @sch.get('nested.doc.simple'), {
                    type: types.String
                    required: true
                }
                utils.assertEqualObj @sch.get('nested.doc.list'), {
                    type: types.List
                    subtype:
                        type: types.String
                        auth:
                            read: true
                }
                utils.assertEqualObj @sch.get('nested.doc.doclist'), {
                    type: types.List
                    schema:
                        _id:
                            type: types.Id
                        simple1:
                            type: types.String
                        simple2:
                            type: types.String
                            required: true
                }
                utils.assertEqualObj @sch.get('nested.doc.doclist.0.simple1'), {
                    type: types.String
                }
                utils.assertEqualObj @sch.get('nested.doc.doclist.simple2'), {
                    type: types.String
                    required: true
                }
                               
    describe 'path extraction functions', ->
        beforeEach ->
            @sch = new Schema(
                simple1: types.String
                simple2:
                    type: types.String
                    required: true
                sub: {
                    simple1: types.String
                    simple2:
                        type: types.String
                        required: true
                }
                list1: [types.String]
                list2: [
                    type: types.String
                    auth:
                        read: true
                ]
                doclist1: [
                    simple1: types.String
                    simple2:
                        type: types.String
                        required: true
                ]
                doclist2:
                    type: types.List
                    schema:
                        simple1: types.String
                        simple2:
                            type: types.String
                            required: true
                nested:
                    simple: types.String
                    list: [types.String]
                    doclist: [
                        simple:
                            type: types.String
                            required: true
                    ]
                    doc:
                        simple:
                            type: types.String
                            required: true
                        list: [
                            type: types.String
                            auth:
                                read: true
                        ]
                        doclist:
                            type: types.List
                            schema:
                                simple1: types.String
                                simple2:
                                    type: types.String
                                    required: true
            )

        it 'work for all paths', ->
            assert.sameMembers paths.all(@sch), [
                '_id'
                'simple1'
                'simple2'
                'sub'
                'sub._id'
                'sub.simple1'
                'sub.simple2'
                'list1'
                'list2'
                'doclist1'
                'doclist1._id'
                'doclist1.simple1'
                'doclist1.simple2'
                'doclist2'
                'doclist2._id'
                'doclist2.simple1'
                'doclist2.simple2'
                'nested'
                'nested._id'
                'nested.simple'
                'nested.list'
                'nested.doclist'
                'nested.doclist._id'
                'nested.doclist.simple'
                'nested.doc'
                'nested.doc._id'
                'nested.doc.simple'
                'nested.doc.list'
                'nested.doc.doclist'
                'nested.doc.doclist._id'
                'nested.doc.doclist.simple1'
                'nested.doc.doclist.simple2'
            ]

        it 'work for primitive paths', ->
            assert.sameMembers paths.primitives(@sch), [
                '_id'
                'simple1'
                'simple2'
                'sub._id'
                'sub.simple1'
                'sub.simple2'
                'list1'
                'list2'
                'doclist1._id'
                'doclist1.simple1'
                'doclist1.simple2'
                'doclist2._id'
                'doclist2.simple1'
                'doclist2.simple2'
                'nested._id'
                'nested.simple'
                'nested.list'
                'nested.doclist._id'
                'nested.doclist.simple'
                'nested.doc._id'
                'nested.doc.simple'
                'nested.doc.list'
                'nested.doc.doclist._id'
                'nested.doc.doclist.simple1'
                'nested.doc.doclist.simple2'
            ]

        it 'work to find schemas with arbitrary properties', ->
            assert.sameMembers paths.withTrueProp(@sch, 'required'), [
                'simple2'
                'sub.simple2'
                'doclist1.simple2'
                'doclist2.simple2'
                'nested.doclist.simple'
                'nested.doc.simple'
                'nested.doc.doclist.simple2'
            ]

    describe 'Endpoint object', ->
        defaultPaths = (obj) ->
            resp = 
                references: {}
                alloweds: {}
                requireds: {}
                uniques: {}
                autos: {}
                autoInits: {}
                docs: {}
                lists: {}
                dates: {}
                defaults: {}
            for key of obj
                resp[key] = obj[key]
            resp
        
        it 'handles a simple schema', ->
            dut = new Endpoint {
                name: String
            }
            utils.assertEqualObj dut, {
                auth:
                    create: true
                    read: true
                    edit: true
                    delete: true

                schema:
                    __proto__: dut.schema.__proto__
                    _id:
                        type: types.Id
                    name:
                        type: String
                paths: defaultPaths()
            }

        it 'handles a simple schema with reference', ->
            dut = new Endpoint {
                name: String
                ref:
                    type: Reference
                    collection: 'users'
                    fields: ['name']
            }
            utils.assertEqualObj dut, {
                auth:
                    create: true
                    read: true
                    edit: true
                    delete: true

                schema:
                    __proto__: dut.schema.__proto__
                    _id:
                        type: types.Id
                    name:
                        type: String
                    ref:
                        type: Reference
                        collection: 'users'
                        fields: ['name']
                paths: defaultPaths(
                    references:
                        ref: dut.schema.ref
                )
            }
            
        it 'handles a simple schema with auth', ->
            dut = new Endpoint {
                auth:
                    edit: false
                schema:
                    name: String
            }
            utils.assertEqualObj dut, {
                auth:
                    create: true
                    read: true
                    edit: false
                    delete: true
                schema:
                    __proto__: dut.schema.__proto__
                    _id:
                        type: types.Id
                    name:
                        type: String
                paths: defaultPaths()
            }

        it 'handles schema with nested and listed reference', ->
            dut = new Endpoint {
                name: String
                subdoc:
                    main_ref:
                        type: Reference
                        collection: 'users'
                        fields: ['name']
                    list:
                        type: List
                        subtype:
                            type: Reference
                            collection: 'users'
                            fields: ['name']
            }
            utils.assertEqualObj dut, {
                auth:
                    create: true
                    read: true
                    edit: true
                    delete: true

                schema:
                    __proto__: dut.schema.__proto__
                    _id:
                        type: types.Id
                    name:
                        type: String
                    subdoc:
                        type: Doc
                        schema:
                            _id:
                                type: types.Id
                            main_ref:
                                type: Reference
                                collection: 'users'
                                fields: ['name']
                            list:
                                type: List
                                subtype:
                                    type: Reference
                                    collection: 'users'
                                    fields: ['name']
                paths: defaultPaths(
                    references:
                        'subdoc.main_ref': dut.schema.subdoc.schema.main_ref
                        'subdoc.list': dut.schema.subdoc.schema.list
                    docs:
                        'subdoc': dut.schema.subdoc
                )
            }

        it 'handles nested schema with alloweds', ->
            dut = new Endpoint {
                name: String
                subdoc:
                    stage:
                        type: String
                        allowed: ['Open', 'Closed']
                    list:
                        type: List
                        subtype:
                            type: String
                            allowed: ['Open', 'Closed']
                list:
                    type: List
                    schema:
                        stage:
                            type: String
                            allowed: ['Open', 'Closed']
            }
            utils.assertEqualObj dut, {
                auth:
                    create: true
                    read: true
                    edit: true
                    delete: true

                schema:
                    __proto__: dut.schema.__proto__
                    _id:
                        type: types.Id
                    name:
                        type: String
                    subdoc:
                        type: Doc
                        schema:
                            _id:
                                type: types.Id
                            stage:
                                type: String
                                allowed: ['Open', 'Closed']
                            list:
                                type: List
                                subtype:
                                    type: String
                                    allowed: ['Open', 'Closed']
                    list:
                        type: List
                        schema:
                            _id:
                                type: types.Id
                            stage:
                                type: String
                                allowed: ['Open', 'Closed']
                paths: defaultPaths(
                    alloweds:
                        'subdoc.stage': dut.schema.subdoc.schema.stage
                        'subdoc.list': dut.schema.subdoc.schema.list
                        'list.stage': dut.schema.list.schema.stage
                    docs:
                        'subdoc': dut.schema.subdoc
                    lists:
                        'list': dut.schema.list
                )
            }

        it 'handles nested schema with requireds', ->
            dut = new Endpoint {
                name: String
                subdoc:
                    stage:
                        type: String
                        required: true
                    list:
                        type: List
                        subtype:
                            type: String
                            required: true
                list:
                    type: List
                    schema:
                        stage:
                            type: String
                            required: true
            }
            utils.assertEqualObj dut, {
                auth:
                    create: true
                    read: true
                    edit: true
                    delete: true

                schema:
                    __proto__: dut.schema.__proto__
                    _id:
                        type: types.Id
                    name:
                        type: String
                    subdoc:
                        type: Doc
                        schema:
                            _id:
                                type: types.Id
                            stage:
                                type: String
                                required: true
                            list:
                                type: List
                                subtype:
                                    type: String
                                    required: true
                    list:
                        type: List
                        schema:
                            _id:
                                type: types.Id
                            stage:
                                type: String
                                required: true
                paths: defaultPaths(
                    requireds:
                        'subdoc.stage': dut.schema.subdoc.schema.stage
                        'subdoc.list': dut.schema.subdoc.schema.list
                        'list.stage': dut.schema.list.schema.stage
                    docs:
                        'subdoc': dut.schema.subdoc
                    lists:
                        'list': dut.schema.list
                )
            }

        it 'handles nested schema with uniques', ->
            dut = new Endpoint {
                name: String
                subdoc:
                    stage:
                        type: String
                        unique: true
                    list:
                        type: List
                        subtype:
                            type: String
                            unique: true
                list:
                    type: List
                    schema:
                        stage:
                            type: String
                            unique: true
            }
            utils.assertEqualObj dut, {
                auth:
                    create: true
                    read: true
                    edit: true
                    delete: true

                schema:
                    __proto__: dut.schema.__proto__
                    _id:
                        type: types.Id
                    name:
                        type: String
                    subdoc:
                        type: Doc
                        schema:
                            _id:
                                type: types.Id
                            stage:
                                type: String
                                unique: true
                            list:
                                type: List
                                subtype:
                                    type: String
                                    unique: true
                    list:
                        type: List
                        schema:
                            _id:
                                type: types.Id
                            stage:
                                type: String
                                unique: true
                paths: defaultPaths(
                    uniques:
                        'subdoc.stage': dut.schema.subdoc.schema.stage
                        'subdoc.list': dut.schema.subdoc.schema.list
                        'list.stage': dut.schema.list.schema.stage
                    docs:
                        'subdoc': dut.schema.subdoc
                    lists:
                        'list': dut.schema.list
                )
            }

        it 'handles nested schema with auto functions', ->
            dut = new Endpoint {
                name: String
                subdoc:
                    stage:
                        type: Auto
                        auto: (el, root) -> root.name
                    list:
                        type: List
                        subtype:
                            type: Auto
                            auto: (el, root) -> root.name
                list:
                    type: List
                    schema:
                        stage:
                            type: Auto
                            auto: (el, root) -> root.name
            }
            utils.assertEqualObj dut, {
                auth:
                    create: true
                    read: true
                    edit: true
                    delete: true

                schema:
                    __proto__: dut.schema.__proto__
                    _id:
                        type: types.Id
                    name:
                        type: String
                    subdoc:
                        type: Doc
                        schema:
                            _id:
                                type: types.Id
                            stage:
                                type: Auto
                                auto: dut.schema.subdoc.schema.stage.auto
                            list:
                                type: List
                                subtype:
                                    type: Auto
                                    auto: dut.schema.subdoc.schema.list.subtype.auto
                    list:
                        type: List
                        schema:
                            _id:
                                type: types.Id
                            stage:
                                type: Auto
                                auto: dut.schema.list.schema.stage.auto
                paths: defaultPaths(
                    autos:
                        'subdoc.stage': dut.schema.subdoc.schema.stage
                        'subdoc.list': dut.schema.subdoc.schema.list
                        'list.stage': dut.schema.list.schema.stage
                    docs:
                        'subdoc': dut.schema.subdoc
                    lists:
                        'list': dut.schema.list
                )
            }

        it 'handles nested schema with autoInit functions', ->
            dut = new Endpoint {
                name: String
                subdoc:
                    stage:
                        type: AutoInit
                        auto: (el, root) -> root.name
                    list:
                        type: List
                        subtype:
                            type: AutoInit
                            auto: (el, root) -> root.name
                list:
                    type: List
                    schema:
                        stage:
                            type: AutoInit
                            auto: (el, root) -> root.name
            }
            utils.assertEqualObj dut, {
                auth:
                    create: true
                    read: true
                    edit: true
                    delete: true

                schema:
                    _id:
                        type: types.Id
                    name:
                        type: String
                    subdoc:
                        type: Doc
                        schema:
                            _id:
                                type: types.Id
                            stage:
                                type: AutoInit
                                auto: dut.schema.subdoc.schema.stage.auto
                            list:
                                type: List
                                subtype:
                                    type: AutoInit
                                    auto: dut.schema.subdoc.schema.list.subtype.auto
                    list:
                        type: List
                        schema:
                            _id:
                                type: types.Id
                            stage:
                                type: AutoInit
                                auto: dut.schema.list.schema.stage.auto
                paths: defaultPaths(
                    autoInits:
                        'subdoc.stage': dut.schema.subdoc.schema.stage
                        'subdoc.list': dut.schema.subdoc.schema.list
                        'list.stage': dut.schema.list.schema.stage
                    docs:
                        'subdoc': dut.schema.subdoc
                    lists:
                        'list': dut.schema.list
                )
            }

    describe 'prototype generation', ->
        it 'handles a simple schema', ->
            sch = new Schema {
                name: String
            }
            dut = prototype(sch)
            utils.assertEqualObj dut, {
                __proto__: dut.__proto__
                _id:null
                name: null
            }
            
            
        it 'handles nested docs, nested lists, and simple lists', ->
            sch = new Schema {
                name: String
                subdoc:
                    name: String
                    list: [
                        name: String
                    ]
                    list2: [
                        name: String
                    ]
                list: [
                    name: String
                ]
            }
            dut = prototype(sch)
            utils.assertEqualObj dut, {
                __proto__: dut.__proto__
                _id: null
                name: null
                subdoc:
                    _id: null
                    name: null
                    list: []
                    list2: []
                list: []
            }
