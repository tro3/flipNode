assert = require('chai').assert
equivObject = require('./lib/utils').equivObject
p = console.log

schema = require('../src/schema')
Schema = schema.Schema
expand = schema.expand
types =  schema.types


describe 'Schema module', ->

    describe 'expand function', ->
        it 'handles simple types', ->
            cfg =
                name: types.String
            assert.deepEqual expand(cfg), {
                name:
                    type: types.String
            }

        it 'handles complex types', ->
            cfg =
                name:
                    type: types.String
                    required: true
            assert.deepEqual expand(cfg), {
                name:
                    type: types.String
                    required: true
            }

        it 'handles simple subdocs', ->
            cfg =
                address:
                    street: types.String
                    city: types.String
            debugger
            assert.deepEqual expand(cfg), {
                address:
                    type: types.Dict
                    schema:
                        street:
                            type: types.String
                        city:
                            type: types.String
            }

        it 'handles complex subdocs', ->
            cfg =
                address:
                    type: types.Dict
                    schema:
                        street: types.String
                        city: types.String
            assert.deepEqual expand(cfg), {
                address:
                    type: types.Dict
                    schema:
                        street:
                            type: types.String
                        city:
                            type: types.String
            }

        it 'handles simple lists', ->
            cfg =
                tags: [types.String]
            assert.deepEqual expand(cfg), {
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
            assert.deepEqual expand(cfg), {
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
            assert.deepEqual expand(cfg), {
                address:
                    type: types.List
                    schema:
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
            assert.deepEqual expand(cfg), {
                address:
                    type: types.List
                    schema:
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
            assert.deepEqual expand(cfg), {
                subdoc:
                    type: types.Dict
                    schema:
                        subdoclist:
                            type: types.List
                            schema:
                                name:
                                    type:types.String
                sublist:
                    type: types.List
                    schema:
                        subdoc:
                            type: types.Dict
                            schema:
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
                assert.deepEqual @sch.get('simple1'), {
                    type: types.String
                }
                assert.deepEqual @sch.get('simple2'), {
                    type: types.String
                    required: true
                }
                
            it 'handles subdocs', ->
                assert.deepEqual @sch.get('sub.simple1'), {
                    type: types.String
                }
                assert.deepEqual @sch.get('sub.simple2'), {
                    type: types.String
                    required: true
                }                
                
            it 'handles simple lists', ->
                assert.deepEqual @sch.get('list1'), {
                    type: types.List
                    subtype:
                        type: types.String
                }
                assert.deepEqual @sch.get('list2'), {
                    type: types.List
                    subtype:
                        type: types.String
                        auth:
                            read: true
                }                

            it 'handles lists of docs', ->
                assert.deepEqual @sch.get('doclist1.simple1'), {
                    type: types.String
                }
                assert.deepEqual @sch.get('doclist2.1.simple2'), {
                    type: types.String
                    required: true
                }               
            
            it 'handles nested docs and lists', ->
                assert.deepEqual @sch.get('nested.simple'), {
                    type: types.String
                }
                assert.deepEqual @sch.get('nested.list'), {
                    type: types.List
                    subtype:
                        type: types.String
                }
                assert.deepEqual @sch.get('nested.doclist.simple'), {
                    type: types.String
                    required: true
                }
                assert.deepEqual @sch.get('nested.doc.simple'), {
                    type: types.String
                    required: true
                }
                assert.deepEqual @sch.get('nested.doc.list'), {
                    type: types.List
                    subtype:
                        type: types.String
                        auth:
                            read: true
                }
                assert.deepEqual @sch.get('nested.doc.doclist'), {
                    type: types.List
                    schema:
                        simple1:
                            type: types.String
                        simple2:
                            type: types.String
                            required: true
                }
                assert.deepEqual @sch.get('nested.doc.doclist.0.simple1'), {
                    type: types.String
                }
                assert.deepEqual @sch.get('nested.doc.doclist.simple2'), {
                    type: types.String
                    required: true
                }
                
                
                