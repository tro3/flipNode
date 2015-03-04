assert = require('chai').assert
equivObject = require('./lib/utils').equivObject
p = console.log


expand = require('../src/schema').expand
types = require('../src/schema').types


describe 'Schema module', ->

    describe 'expand function', ->
        beforeEach ->
            @type = () ->
                
        it 'handles simple types', ->
            cfg =
                name: @type
            assert.deepEqual expand(cfg), {
                name:
                    type: @type
            }
            
        it 'handles complex types', ->
            cfg =
                name:
                    type: @type
                    required: true
            assert.deepEqual expand(cfg), {
                name:
                    type: @type
                    required: true
            }

        it 'handles simple subdocs', ->
            cfg =
                address:
                    street: @type
                    city: @type
            debugger
            assert.deepEqual expand(cfg), {
                address:
                    type: types.Dict
                    schema:
                        street:
                            type: @type
                        city:
                            type: @type
            }
        
        it 'handles complex subdocs', ->
            cfg =
                address:
                    type: types.Dict
                    schema:
                        street: @type
                        city: @type
            p expand(cfg)
            assert.deepEqual expand(cfg), {
                address:
                    type: types.Dict
                    schema:
                        street:
                            type: @type
                        city:
                            type: @type
            }
            
        it 'handles simple lists', ->
            cfg =
                tags: [@type]
            assert.deepEqual expand(cfg), {
                tags:
                    type: types.List
                    subtype: @type
            }
            
        it 'handles complex lists', ->
            cfg =
                tags:
                    type: types.List
                    subtype: @type
            assert.deepEqual expand(cfg), {
                tags:
                    type: types.List
                    subtype: @type
            }
        
        it 'handles simple lists of objects', ->
            cfg =
                address: [
                    street: @type
                    city: @type
                ]
            assert.deepEqual expand(cfg), {
                address:
                    type: types.List
                    schema:
                        street:
                            type: @type
                        city:
                            type: @type
            }
            
        it 'handles complex lists of objects', ->
            cfg =
                address:
                    type: types.List
                    schema:
                        street:
                            type: @type
                        city:
                            type: @type
            assert.deepEqual expand(cfg), {
                address:
                    type: types.List
                    schema:
                        street:
                            type: @type
                        city:
                            type: @type
            }
            
        it 'handles nested objects and lists', ->
            cfg =
                subdoc:
                    subdoclist: [
                        name: @type
                    ]
                sublist: [
                    subdoc:
                        address: @type
                ]
            assert.deepEqual expand(cfg), {
                subdoc:
                    type: types.Dict
                    schema:
                        subdoclist:
                            type: types.List
                            schema:
                                name:
                                    type:@type
                sublist:
                    type: types.List
                    schema:
                        subdoc:
                            type: types.Dict
                            schema:
                                address:
                                    type: @type
            }
