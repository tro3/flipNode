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
    
    it.skip 'responds with a 404 for non-existent collection', (done) ->
        app = express()
        app.use '/api', flip.api conn,
            users:
                name: types.String
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            data = {_id:1, name:'admin2'}
            request(app)
                .put('/api/frogs/1')
                .set('Content-Type', 'application/json')
                .send(data)
                .expect(404)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        done()
        .catch (err) -> done(err)

    it.skip 'responds with a 404 for non-existent document', (done) ->
        app = express()
        app.use '/api', flip.api conn,
            users:
                name: types.String
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            data = {_id:1, name:'admin2'}
            request(app)
                .put('/api/users/2')
                .set('Content-Type', 'application/json')
                .send(data)
                .expect(404)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        done()
        .catch (err) -> done(err)

    it.skip 'responds with a 400 for for mismatched id', (done) ->
        app = express()
        app.use '/api', flip.api conn,
            users:
                name: types.String
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            data = {_id:2, name:'admin2'}
            request(app)
                .put('/api/users/1')
                .set('Content-Type', 'application/json')
                .send(data)
                .expect(400)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        done()
        .catch (err) -> done(err)

    it.skip 'responds with a 400 for for garbled data', (done) ->
        app = express()
        app.use '/api', flip.api conn,
            users:
                name: types.String
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            data = {_id:2, name:'admin2'}
            request(app)
                .put('/api/users/1')
                .set('Content-Type', 'application/json')
                .send("I am bob")
                .expect(400)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        done()
        .catch (err) -> done(err)

    it.skip 'responds with a 403 for edit auth constant false', (done) ->
        app = express()
        app.use '/api', flip.api conn,
            users:
                auth:
                    edit: false
                schema:
                    name: types.String
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            data = {_id:1, name:'admin2'}
            request(app)
                .put('/api/users/1')
                .set('Content-Type', 'application/json')
                .send(data)
                .expect(403)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        done()
        .catch (err) -> done(err)

    it.skip 'responds with a 403 for edit auth function false', (done) ->
        app = express()
        app.use '/api', flip.api conn,
            users:
                auth:
                    edit: -> false
                schema:
                    name: types.String
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            data = {_id:1, name:'admin2'}
            request(app)
                .put('/api/users/1')
                .set('Content-Type', 'application/json')
                .send(data)
                .expect(403)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        done()
        .catch (err) -> done(err)
    
    it.skip 'responds with _status=ERR for wrong data types', (done) ->
        app.use '/api', flip.api conn,
            users:
                eid: types.Integer
        conn.insert('users', {_id:1, eid:408})
        .then ->
            data = {_id:1, eid:'admin2'}
            request(app)
                .put('/api/users/1')
                .set('Content-Type', 'application/json')
                .send(data)
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        assert.deepEqual res.body,
                            _status: 'ERR'
                            _errs: [
                                {path: 'eid', msg: "Could not convert 'eid' value of 'admin2'"}
                            ]
                        done()
        .catch (err) -> done(err)
