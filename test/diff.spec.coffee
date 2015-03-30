assert = require('chai').assert

diff = require('../src/viewFunctions/diff')
p = console.log


describe 'diff function', ->
        
    it 'compares simple flat objects', ->
        o =
            a:1
            b:2
        n =
            a:2
            c:3
        assert.deepEqual diff(o,n), [
            {action:'field changed', objPath: '', field:'a', old:1, new:2}
            {action:'field removed', objPath: '', field:'b', old:2}
            {action:'field added',   objPath: '', field:'c', new:3}
        ]

    it 'handles addition of nested object', ->
        o =
            a:1
        n =
            a:1
            b: {a:1}
        assert.deepEqual diff(o,n), [
            {action:'field added',   objPath: '', field:'b', new:{a:1}}
        ]
   
    it 'handles removal of nested object', ->
        o =
            a:1
            b: {a:1}
        n =
            a:1
        assert.deepEqual diff(o,n), [
            {action:'field removed',   objPath: '', field:'b', old:{a:1}}
        ]

    it 'handles addition of list of objects', ->
        o =
            a:1
        n =
            a:1
            b: [{a:1}]
        assert.deepEqual diff(o,n), [
            {action:'field added',   objPath: '', field:'b', new:[{a:1}]}
        ]
   
    it 'handles removal of list of objects', ->
        o =
            a:1
            b: [{a:1}]
        n =
            a:1
        assert.deepEqual diff(o,n), [
            {action:'field removed',   objPath: '', field:'b', old:[{a:1}]}
        ]

    it 'handles changes in nested object', ->
        o =
            a:
                a:1
                b:2
        n =
            a:
                a:2
                c:3
        assert.deepEqual diff(o,n), [
            {action:'field changed', objPath: 'a', field:'a', old:1, new:2}
            {action:'field removed', objPath: 'a', field:'b', old:2}
            {action:'field added',   objPath: 'a', field:'c', new:3}
        ]

    it 'handles changes in doubly-nested object', ->
        o =
            a:
                a:
                    a:1
                    b:2
        n =
            a:
                a:
                    a:2
                    c:3
        assert.deepEqual diff(o,n), [
            {action:'field changed', objPath: 'a.a', field:'a', old:1, new:2}
            {action:'field removed', objPath: 'a.a', field:'b', old:2}
            {action:'field added',   objPath: 'a.a', field:'c', new:3}
        ]

    it 'handles adding item to list', ->
        o =
            a: [1]
        n =
            a: [1,2]
        assert.deepEqual diff(o,n), [
            {action:'item added', objPath: '', field:'a', new:2, index:1}
        ]

    it 'handles removing item from list', ->
        o =
            a: [1,2]
        n =
            a: [1]
        assert.deepEqual diff(o,n), [
            {action:'item removed', objPath: '', field:'a', old:2, index:1}
        ]

    it 'handles reordering list', ->
        o =
            a: [1,2]
        n =
            a: [2,1]
        assert.deepEqual diff(o,n), [
            {action:'items reordered', objPath: '', field:'a', old:[1,2], new:[2,1]}
        ]

    it 'handles simultaneous add, remove, and reordering list', ->
        o =
            a: [1,2,3]
        n =
            a: [2,1,4]
        assert.deepEqual diff(o,n), [
            {action:'item removed', objPath: '', field:'a', old:3, index:2}
            {action:'items reordered', objPath: '', field:'a', old:[1,2], new:[2,1]}
            {action:'item added', objPath: '', field:'a', new:4, index:2}
        ]

    it 'handles simultaneous add, remove, and reordering nested list of objects', ->
        o =
            a:
                a:[
                    {_id:1, a:2}
                    {_id:2, a:4}
                    {_id:3, a:6}
                ]
        n =
            a:
                a:[
                    {_id:3, a:6}
                    {_id:2, a:4}
                    {_id:4, a:8}
                ]
        assert.deepEqual diff(o,n), [
            {action:'item removed', objPath: 'a', field:'a', old:{_id:1, a:2}, index:0}
            {action:'items reordered', objPath: 'a', field:'a', old:[2,3], new:[3,2]}
            {action:'item added', objPath: 'a', field:'a', new:{_id:4, a:8}, index:2}
        ]
