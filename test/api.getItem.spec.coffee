assert = require('chai').assert
request = require('supertest')
express = require('express')
flip = require('../src')
types = flip.schema.types
connect = require('../src/api/db').connect



describe 'api.getItem', ->
    app = null
    conn = null
    
    before ->
        conn = connect('mongodb://localhost:27017/test')
                
    beforeEach ->
        app = express()

    afterEach (done) ->
        conn.drop('users')
        .finally -> done()

    it 'responds with a simple item', (done) ->
        app.use '/api', flip.api conn,
            users:
                name: types.String
        conn.insert('users', {_id:1, name:'admin', city:'Menlo Park'})
        .then ->
            request(app)
                .get('/api/users/1')
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        assert.deepEqual res.body,
                            _status: 'OK'
                            _item:
                                _id:1
                                _auth:
                                    _edit: true
                                    _delete: true
                                name: 'admin'
                                city: 'Menlo Park'
                        done()
        .catch (err) -> done(err)

    it 'responds with a 404 for non-existent collection', (done) ->
        app.use '/api', flip.api conn,
            users:
                name: types.String
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            request(app)
                .get('/api/frogs/1')
                .expect(404)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        done()
        .catch (err) -> done(err)

    it 'responds with a 404 for non-existent document', (done) ->
        app.use '/api', flip.api conn,
            users:
                name: types.String
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            request(app)
                .get('/api/users/2')
                .expect(404)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        done()
        .catch (err) -> done(err)

    it 'responds with a 403 for read auth constant false', (done) ->
        app.use '/api', flip.api conn,
            users:
                auth:
                    read: false
                schema:
                    name: types.String
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            request(app)
                .get('/api/users/1')
                .expect(403)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        done()
        .catch (err) -> done(err)

    it 'responds with a 403 for read auth function false', (done) ->
        app.use '/api', flip.api conn,
            users:
                auth:
                    read: -> false
                schema:
                    name: types.String
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            request(app)
                .get('/api/users/1')
                .expect(403)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        done()
        .catch (err) -> done(err)

    it 'handles a simple item with a subset of fields', (done) ->
        app.use '/api', flip.api conn,
            users:
                name: types.String
        conn.insert('users', {_id:1, name:'admin', city:'Menlo Park'})
        .then ->
            request(app)
                .get('/api/users/1?fields={"city":1}')
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        assert.deepEqual res.body,
                            _status: 'OK'
                            _item:
                                _id:1
                                _auth:
                                    _edit: true
                                    _delete: true
                                city: 'Menlo Park'
                        done()
        .catch (err) -> done(err)

    it 'emits an event on read item', (done) ->
        api = flip.api conn,
            users:
                name: types.String
        app.use '/api', api
        tests = {}
        [
            'pre'
            'read.pre'
            'users.read.pre'
        ].forEach (x) ->
            tests[x] = false
            api.events.on x, (req, res) ->
                assert.equal req.collection, 'users'
                assert.equal req.id, 1
                tests[x] = true
        [
            'post'
            'read.post'
            'users.read.post'
        ].forEach (x) ->
            tests[x] = false
            api.events.on x, (req, res) ->
                assert.equal req.collection, 'users'
                assert.equal req.id, 1
                assert.deepEqual res.body,
                    _status: 'OK'
                    _item:
                        _id:1
                        _auth:
                            _edit: true
                            _delete: true
                        name: 'admin'
                        city: 'Menlo Park'
                tests[x] = true
        conn.insert('users', {_id:1, name:'admin', city:'Menlo Park'})
        .then ->
            request(app)
                .get('/api/users/1')
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        assert.deepEqual tests,
                            'pre': true
                            'post': true
                            'read.pre': true
                            'users.read.pre': true
                            'read.post': true
                            'users.read.post': true
                        assert.deepEqual res.body,
                            _status: 'OK'
                            _item:
                                _id:1
                                _auth:
                                    _edit: true
                                    _delete: true
                                name: 'admin'
                                city: 'Menlo Park'
                        done()
        .catch (err) -> done(err)
