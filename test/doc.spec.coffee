assert = require('chai').assert
Doc = require('../src/doc').Doc
equivObject = require('./lib/utils').equivObject
p = console.log





describe 'Doc object', ->

    describe 'get', ->
            
        it 'works on simple nested objects', ->
            inst = new Doc(
                a:1
                b:2
                c:
                    d:3
                    e:4
            )
            assert.equal inst.get('a'), 1
            assert.equal inst.get('b'), 2
            assert.equal inst.get('c.d'), 3
            assert.equal inst.get('c.e'), 4

        it 'works on lists and lists of objects', ->
            inst = new Doc(
                a:1
                b: [2, 3]
                c: [{d:4,e:5},{d:6,e:7}]
            )
            assert.equal inst.get('a'), 1
            assert.equal inst.get('b.0'), 2
            assert.equal inst.get('b.1'), 3
            assert.equal inst.get('c.0.d'), 4
            assert.equal inst.get('c.0.e'), 5
            assert.equal inst.get('c.1.d'), 6
            assert.equal inst.get('c.1.e'), 7


    describe 'set', ->
            
        it 'works on simple nested objects', ->
            inst = new Doc(c:{})
            inst.set('a', 1)
            inst.set('b', 2)
            inst.set('c.d', 3)
            inst.set('c.e', 4)
            
            assert.isTrue equivObject inst, {
                a:1
                b:2
                c:
                    d:3
                    e:4
            }
            

        it 'works on lists and lists of objects', ->
            inst = new Doc(
                b: []
                c: [{},{}]
            )
            inst.set('a', 1)
            inst.set('b.0', 2)
            inst.set('b.1', 3)
            inst.set('c.0.d', 4)
            inst.set('c.0.e', 5)
            inst.set('c.1.d', 6)
            inst.set('c.1.e', 7)
            assert.isTrue equivObject inst, {
                a: 1
                b: [2, 3]
                c: [{d:4,e:5},{d:6,e:7}]
            }
