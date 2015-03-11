assert = require('chai').assert
sinon = require('sinon')
Collection = require('mongodb/lib/collection')

DbCache = require('../src/db/dbCache')
p = console.log



describe 'dbCache', ->
    db = null
    
    beforeEach ->
        db = new DbCache('mongodb://localhost:27017/test')

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

    describe 'update', ->
        it 'modifies single doc', (done) ->
            db.insert('test', {a:3})
            .then -> db.update('test', {a:3}, {a:1})
            .then -> db.findOne('test')
            .then (doc) ->
                assert.equal doc.a, 1
                done()
            .catch (err) -> done(err)

    describe 'updateMany', ->
        it 'modifies multiple docs', (done) ->
            db.insert('test', [{i:2, a:1}, {i:1, a:2}])
            .then -> db.updateMany('test', {}, {$inc:{a:1}})
            .then -> db.find('test', {}, {sort:{i:1}})
            .then (docs) ->
                assert.equal docs[0].a, 3
                assert.equal docs[1].a, 2
                done()
            .catch (err) -> done(err)

    describe 'find', ->
        spy1 = null
        spy2 = null
        callCount = -> spy1.callCount + spy2.callCount
        
        beforeEach ->
            spy1 = sinon.spy(db.db, 'find')
            spy2 = sinon.spy(db.db, 'findOne')
            
        afterEach ->
            db.db.find.restore()
            db.db.findOne.restore()
            
        it 'handles basic request', (done) ->
            db.insert('test', [{a:1,b:1},{a:2,b:2},{a:3,b:1},{a:4,b:2}])
            .then -> db.find('test', {b:{$ne:1}}, {sort:{a:1}})
            .then (docs) ->
                assert.equal docs.length, 2
                assert.equal docs[0].a, 2
                assert.equal docs[1].a, 4
                assert.equal callCount(), 1
                done()
            .catch (err) -> done(err)

        it 'only checks db once for two equal multi queries', (done) ->
            db.insert('test', [{a:1,b:1},{a:2,b:2},{a:3,b:1},{a:4,b:2}])
            .then -> db.find('test', {b:{$ne:1}}, {sort:{a:1}})
            .then -> assert.equal callCount(), 1
            .then -> db.find('test', {b:{$ne:1}}, {sort:{a:1}})
            .then (docs) ->
                assert.equal docs.length, 2
                assert.equal docs[0].a, 2
                assert.equal docs[1].a, 4
                assert.equal callCount(), 1
                done()
            .catch (err) ->
                done(err)


    describe 'findOne', ->
        spy1 = null
        spy2 = null
        callCount = -> spy1.callCount + spy2.callCount
        
        beforeEach ->
            spy1 = sinon.spy(db.db, 'find')
            spy2 = sinon.spy(db.db, 'findOne')
            
        afterEach ->
            db.db.find.restore()
            db.db.findOne.restore()

        it 'handles basic request', (done) ->
            db.insert('test', [{a:1,b:1},{a:2,b:2},{a:3,b:1},{a:4,b:2}])
            .then -> db.findOne('test', {b:{$ne:1}}, {sort:{a:1}})
            .then (doc) ->
                assert.equal doc.a, 2
                done()
            .catch (err) -> done(err)

        it 'only checks db once for two equal single queries', (done) ->
            db.insert('test', [{a:1,b:1},{a:2,b:2},{a:3,b:1},{a:4,b:2}])
            .then -> db.findOne('test', {a:2})
            .then (doc) ->
                assert.equal doc.a, 2
                assert.equal doc.b, 2
                assert.equal callCount(), 1
            .then -> db.findOne('test', {a:2})
            .then (doc) ->
                assert.equal doc.a, 2
                assert.equal doc.b, 2
                assert.equal callCount(), 1
                done()
            .catch (err) ->
                done(err)

        it 'only checks db once for a multi query followed by an id query', (done) ->
            id = null
            db.insert('test', [{a:1,b:1},{a:2,b:2},{a:3,b:1},{a:4,b:2}])
            .then -> db.find('test', {b:{$ne:1}}, {sort:{a:1}})
            .then (docs) ->
                id = docs[0]._id
                assert.equal callCount(), 1
            .then -> db.findOne('test', {_id:id})
            .then (doc) ->
                assert.equal doc.a, 2
                assert.equal doc.b, 2
                assert.equal callCount(), 1
                done()
            .catch (err) ->
                done(err)


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
