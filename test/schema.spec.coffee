assert = require('chai').assert
equivObject = require('./lib/utils').equivObject
p = console.log


expand = require('../src/schema').expand
types = require('../src/schema').types


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
                    subtype: types.String
            }
            
        it 'handles complex lists', ->
            cfg =
                tags:
                    type: types.List
                    subtype: types.String
            assert.deepEqual expand(cfg), {
                tags:
                    type: types.List
                    subtype: types.String
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
