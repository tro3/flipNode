assert = require('chai').assert
request = require('supertest')
express = require('express')
flip = require('../src')
types = flip.schema.types
connect = require('../src/db').connect

p = console.log


describe 'api.deleteItem', ->
    app = null
    conn = null

    before ->
        conn = connect('mongodb://localhost:27017/test')

    beforeEach ->
        app = express()

    afterEach (done) ->
        conn.drop('users')
        .finally -> conn.drop('flipData.history')
        .finally -> done()

    it 'deletes a simple item', (done) ->
        app.use '/api', flip.api conn,
            users:
                name: types.String
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            request(app)
                .delete('/api/users/1')
                .set('Content-Type', 'application/json')
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        assert.deepEqual res.body,
                            _status: 'OK'
                        conn.count('users', {_id:1}).then (count) ->
                            assert.equal count, 0
                            conn.findOne('flipData.history', {}).then (doc) ->
                                assert.deepEqual doc,
                                    _id: doc._id
                                    collection: 'users'
                                    item: 1
                                    action: 'deleted'
                                    old:
                                        _id: 1
                                        name: 'admin'
                                done()
                        .done null, (err) -> throw err
        .done null, (err) -> done(err)
    
    it 'responds with a 404 for non-existent collection', (done) ->
        app = express()
        app.use '/api', flip.api conn,
            users:
                name: types.String
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            data = {_id:1, name:'admin2'}
            request(app)
                .delete('/api/frogs/1')
                .expect(404)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        conn.find('users', {}).then (docs) ->
                            assert.equal docs.length, 1
                            done()
        .catch (err) -> done(err)

    it 'responds with a 404 for non-existent document', (done) ->
        app = express()
        app.use '/api', flip.api conn,
            users:
                name: types.String
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            data = {_id:1, name:'admin2'}
            request(app)
                .delete('/api/users/2')
                .expect(404)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        conn.find('users', {}).then (docs) ->
                            assert.equal docs.length, 1
                            done()
        .catch (err) -> done(err)

    it 'responds with a 403 for delete auth constant false', (done) ->
        app = express()
        app.use '/api', flip.api conn,
            users:
                auth:
                    delete: false
                schema:
                    name: types.String
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            data = {_id:1, name:'admin2'}
            request(app)
                .delete('/api/users/1')
                .expect(403)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        conn.find('users', {}).then (docs) ->
                            assert.equal docs.length, 1
                            done()
        .catch (err) -> done(err)

    it 'responds with a 403 for delete auth function false', (done) ->
        app = express()
        app.use '/api', flip.api conn,
            users:
                auth:
                    delete: -> false
                schema:
                    name: types.String
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            data = {_id:1, name:'admin2'}
            request(app)
                .delete('/api/users/1')
                .expect(403)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        conn.find('users', {}).then (docs) ->
                            assert.equal docs.length, 1
                            done()
        .catch (err) -> done(err)

    it 'emits an event on delete', (done) ->        
        api = flip.api conn,
            users:
                name: types.String
        app.use '/api', api
        tests = {}
        [
            'delete.pre'
            'users.delete.pre'
            'delete.post'
            'users.delete.post'
        ].forEach (x) ->
            tests[x] = false
            api.events.on x, (req, res) ->
                assert.equal req.collection, 'users'
                assert.equal req.id, 1
                tests[x] = true
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            request(app)
                .delete('/api/users/1')
                .set('Content-Type', 'application/json')
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        assert.deepEqual tests,
                            'delete.pre': true
                            'users.delete.pre': true
                            'delete.post': true
                            'users.delete.post': true
                        assert.deepEqual res.body,
                            _status: 'OK'
                        conn.count('users', {_id:1}).then (count) ->
                            assert.equal count, 0
                            conn.findOne('flipData.history', {}).then (doc) ->
                                assert.deepEqual doc,
                                    _id: doc._id
                                    collection: 'users'
                                    item: 1
                                    action: 'deleted'
                                    old:
                                        _id: 1
                                        name: 'admin'
                                done()
                        .done null, (err) -> throw err
        .done null, (err) -> done(err)
