assert = require('chai').assert
utils = require('../src/utils')
p = console.log


describe 'Utility module', ->

    describe 'execTree', ->
        beforeEach ->
            @paths = []
            @collect = (val, path) =>
                @paths.push(path)
            
        it 'works on simple nested objects', ->
            inst =
                a:1
                b:2
                c:
                    d:1
                    e:2
            utils.execTree inst, @collect
            assert.sameMembers @paths, ['a','b','c','c.d','c.e']

        it 'works on lists and lists of objects', ->
            inst =
                a:1
                b: ['1', '2']
                c: [{d:1,e:2},{d:1,e:2}]
            utils.execTree inst, @collect
            assert.sameMembers @paths, ['a','b','b.0','b.1','c','c.0','c.0.d','c.0.e','c.1','c.1.d','c.1.e']


    describe 'execValTree', ->
        beforeEach ->
            @paths = []
            @collect = (val, path) =>
                @paths.push(path)
            
        it 'works on simple nested objects', ->
            inst =
                a:1
                b:2
                c:
                    d:1
                    e:2
            utils.execValTree inst, @collect
            assert.sameMembers @paths, ['a','b','c.d','c.e']

        it 'works on lists and lists of objects', ->
            inst =
                a:1
                b: ['1', '2']
                c: [{d:1,e:2},{d:1,e:2}]
            utils.execValTree inst, @collect
            assert.sameMembers @paths, ['a','b.0','b.1','c.0.d','c.0.e','c.1.d','c.1.e']



    describe 'execObjTree', ->
        beforeEach ->
            @paths = []
            @collect = (val, path) =>
                @paths.push(path)
            
        it 'works on simple nested objects', ->
            inst =
                a:1
                b:2
                c:
                    d:1
                    e:
                        f:1
                        g:1
            utils.execObjTree inst, @collect
            assert.sameMembers @paths, ['','c','c.e']

        it 'works on lists and lists of objects', ->
            inst =
                a:1
                b: ['1', '2']
                c: [{d:1,e:2},{d:1,e:2}]
            utils.execObjTree inst, @collect
            assert.sameMembers @paths, ['','c.0','c.1']
