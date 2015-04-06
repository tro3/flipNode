assert = require('chai').assert
sinon = require('sinon')
Collection = require('mongodb/lib/collection')

connect = require('../src/api/db/qdb')
DbCache = require('../src/api/db/dbCache')
p = console.log


describe 'dbCache', ->
    conn = null
    spy1 = null
    spy2 = null

    before ->
        conn = connect('mongodb://localhost:27017/test')

    after (done) ->
        conn.close()
        .then -> done()

    beforeEach ->
        spy1 = sinon.spy(conn, 'find')
        spy2 = sinon.spy(conn, 'findOne')

    afterEach (done) ->
        conn.find.restore()
        conn.findOne.restore()
        conn.drop('test')
        .then -> done()

    callCount = -> spy1.callCount + spy2.callCount


    describe 'single instance', ->
        db = null

        beforeEach ->
            db = new DbCache(conn)

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
            beforeEach (done) ->
                db.insert('test', {_id:1, a:3})
                .then -> done()
                                
            it 'modifies single doc', (done) ->
                db.update('test', {a:3}, {_id:1, a:1})
                .then -> db.findOne('test')
                .then (doc) ->
                    assert.equal doc.a, 1
                    done()
                .catch (err) -> done(err)

            it 'invalidates local cache', (done) ->
                db.findOne('test', {_id:1})
                .then (doc) ->
                    assert.equal doc.a, 3
                .then -> db.update('test', {_id:1}, {_id:1, a:1})
                .then -> db.findOne('test', {_id:1})
                .then (doc) ->
                    assert.equal callCount(), 2
                    assert.equal doc.a, 1
                    done()
                .done null, (err) -> done(err)

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
            it 'handles basic request', (done) ->
                db.insert('test', [{a:1,b:1},{a:2,b:2},{a:3,b:1},{a:4,b:2}])
                .then -> db.findOne('test', {b:{$ne:1}}, {sort:{a:1}})
                .then (doc) ->
                    assert.equal doc.a, 2
                    done()
                .catch (err) -> done(err)

            it 'handles no document found', (done) ->
                db.insert('test', [{a:1,b:1},{a:2,b:2},{a:3,b:1},{a:4,b:2}])
                .then -> db.findOne('test', {b:3}, {sort:{a:1}})
                .then (doc) ->
                    assert.equal doc, null
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

        it 'is robust to external doc changes', (done) ->
            db.insert('test', [{a:1,b:1},{a:2,b:2},{a:3,b:1},{a:4,b:2}])
            .then -> db.findOne('test', {a:1})
            .then (doc) ->
                doc.b = 2
                db.findOne('test', {a:1})
            .then (doc) ->
                assert.equal doc.b, 1
                done()
            .done null, (err) -> throw err


    describe 'multi-instance', ->
        db1 = null
        db2 = null

        beforeEach ->
            db1 = new DbCache(conn)
            db2 = new DbCache(conn)

        describe 'find', ->
            it 'only caches local finds', (done) ->
                id = null
                db1.insert('test', [{a:1,b:1},{a:2,b:2},{a:3,b:1},{a:4,b:2}])
                .then -> db1.find('test', {b:{$ne:1}}, {sort:{a:1}})
                .then (docs) ->
                    id = docs[0]._id
                    assert.equal docs.length, 2
                    assert.equal docs[0].a, 2
                    assert.equal docs[1].a, 4
                    assert.equal callCount(), 1
                .then -> db2.find('test', {b:{$ne:1}}, {sort:{a:1}})
                .then (docs) ->
                    assert.equal docs.length, 2
                    assert.equal docs[0].a, 2
                    assert.equal docs[1].a, 4
                    assert.equal callCount(), 2
                .then -> db1.findOne('test', {_id:id})
                .then (doc) ->
                    assert.equal doc.a, 2
                    assert.equal callCount(), 2
                .then -> db2.findOne('test', {_id:id})
                .then (doc) ->
                    assert.equal doc.a, 2
                    assert.equal callCount(), 2
                .then -> db1.findOne('test', {a:1})
                .then (doc) ->
                    assert.equal doc.b, 1
                    assert.equal callCount(), 3
                .then -> db2.findOne('test', {a:1})
                .then (doc) ->
                    assert.equal doc.b, 1
                    assert.equal callCount(), 4
                    done()
                .catch (err) -> done(err)
        