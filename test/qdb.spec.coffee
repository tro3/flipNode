assert = require('chai').assert
sinon = require('sinon')

connect = require('../src/db/qdb')
p = console.log



describe.only 'qdb', ->
    db = null
    
    beforeEach ->
        db = connect('mongodb://localhost:27017/test')

    afterEach (done) ->
        db.drop('test', {})
        .then -> db.close()
        .then -> done()

    describe 'insert', ->
        it 'adds single doc', (done) ->
            db.insert('test', {a:1})
            .then -> db.findOne('test')
            .then (doc) ->
                assert.equal doc.a, 1
                done()
            .catch (err) -> done(err)

        it 'adds multiple docs', (done) ->
            db.insert('test', [{i:2, a:1}, {i:1, b:2}])
            .then -> db.find('test', {}, {sort:{i:1}})
            .then (docs) ->
                assert.equal docs[0].b, 2
                assert.equal docs[1].a, 1
                done()
            .catch (err) -> done(err)

    describe 'find', ->
        it 'handles basic request', (done) ->
            db.insert('test', [{a:1,b:1},{a:2,b:2},{a:3,b:1},{a:4,b:2}])
            .then -> db.find('test', {b:{$ne:1}}, {sort:{a:1}})
            .then (docs) ->
                assert.equal docs.length, 2
                assert.equal docs[0].a, 2
                assert.equal docs[1].a, 4
                done()
            .catch (err) -> done(err)

    describe 'findOne', ->
        it 'handles basic request', (done) ->
            db.insert('test', [{a:1,b:1},{a:2,b:2},{a:3,b:1},{a:4,b:2}])
            .then -> db.findOne('test', {b:{$ne:1}}, {sort:{a:1}})
            .then (doc) ->
                assert.equal doc.a, 2
                done()
            .catch (err) -> done(err)

    describe 'remove', ->
        it 'handles basic request', (done) ->
            db.insert('test', [{a:1,b:1},{a:2,b:2},{a:3,b:1},{a:4,b:2}])
            .then -> db.remove('test', {b:1})
            .then -> db.find('test', {}, {sort:{a:1}})
            .then (docs) ->
                assert.equal docs.length, 2
                assert.equal docs[0].a, 2
                assert.equal docs[1].a, 4
                done()
            .catch (err) -> done(err)

    describe 'drop', ->
        it 'handles basic request', (done) ->
            db.insert('test', [{a:1,b:1},{a:2,b:2},{a:3,b:1},{a:4,b:2}])
            .then -> db.insert('test2', [{a:1,b:1},{a:2,b:2},{a:3,b:1},{a:4,b:2}])
            .then -> db.collections()
            .then (colls) ->
                assert.isTrue 'test2' in (x.s.name for x in colls)
                db.drop('test2')
            .then -> db.collections()
            .then (colls) ->
                assert.isFalse 'test2' in (x.s.name for x in colls)
                done()
            .catch (err) -> done(err)
