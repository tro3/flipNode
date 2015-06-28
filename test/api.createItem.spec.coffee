assert = require('chai').assert
request = require('supertest')
express = require('express')
flip = require('../src')
types = flip.schema.types
connect = require('../src/api/db').connect

p = console.log


describe 'api.createItem', ->
    app = null
    conn = null

    before ->
        conn = connect('mongodb://localhost:27017/test')

    beforeEach (done) ->
        app = express()
        conn.insert('flipData.ids', {collection:'users', lastID:0})
        .then -> done()

    afterEach (done) ->
        conn.drop('users')
        .finally -> conn.drop('flipData.ids')
        .finally -> conn.drop('flipData.history')
        .finally -> done()


    it 'creates a simple item', (done) ->
        app.use '/api', flip.api conn,
            users:
                name: types.String
        data = {name:'admin2'}
        request(app)
            .post('/api/users')
            .set('Content-Type', 'application/json')
            .send(data)
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
                            name: 'admin2'
                    conn.findOne('users', {_id:1}).then (doc) ->
                        assert.deepEqual doc,
                            _id:1
                            name: 'admin2'
                        done()


    it 'adds a _tid param when a simple item is created', (done) ->
        app.use '/api', flip.api conn,
            users:
                name: types.String
        data = {name:'admin2', _tid: '123'}
        request(app)
            .post('/api/users')
            .set('Content-Type', 'application/json')
            .send(data)
            .expect('Content-Type', /json/)
            .expect(200)
            .end (err, res) ->
                if err
                    done(err)
                else
                    assert.deepEqual res.body,
                        _status: 'OK'
                        _tid: '123'
                        _item:
                            _id:1
                            _auth:
                                _edit: true
                                _delete: true
                            name: 'admin2'
                    conn.findOne('users', {_id:1}).then (doc) ->
                        assert.deepEqual doc,
                            _id:1
                            name: 'admin2'
                        done()


    it 'responds with a 404 for non-existent collection', (done) ->
        app.use '/api', flip.api conn,
            users:
                name: types.String
        data = {name:'admin2'}
        request(app)
            .post('/api/frogs')
            .set('Content-Type', 'application/json')
            .send(data)
            .expect(404)
            .end (err, res) ->
                if err
                    done(err)
                else
                    conn.count('users').then (count) ->
                        assert.equal count, 0
                        done()

    it 'responds with a 404 for existing collection, but with id in URL', (done) ->
        app.use '/api', flip.api conn,
            users:
                name: types.String
        data = {name:'admin2'}
        request(app)
            .post('/api/users/1')
            .set('Content-Type', 'application/json')
            .send(data)
            .expect(404)
            .end (err, res) ->
                if err
                    done(err)
                else
                    conn.count('users').then (count) ->
                        assert.equal count, 0
                        done()

    it 'responds with a 400 for existing collection, but with id in data', (done) ->
        app.use '/api', flip.api conn,
            users:
                name: types.String
        data = {_id:1, name:'admin2'}
        request(app)
            .post('/api/users')
            .set('Content-Type', 'application/json')
            .send(data)
            .expect(400)
            .end (err, res) ->
                if err
                    done(err)
                else
                    conn.count('users').then (count) ->
                        assert.equal count, 0
                        done()

    it 'responds with a 400 for for garbled data', (done) ->
        app.use '/api', flip.api conn,
            users:
                name: types.String
        data = {_id:2, name:'admin2'}
        request(app)
            .post('/api/users')
            .set('Content-Type', 'application/json')
            .send("I am bob")
            .expect(400)
            .end (err, res) ->
                if err
                    done(err)
                else
                    conn.count('users').then (count) ->
                        assert.equal count, 0
                        done()

    it 'responds with a 403 for create auth constant false', (done) ->
        app.use '/api', flip.api conn,
            users:
                auth:
                    create: false
                schema:
                    name: types.String
        data = {_id:1, name:'admin2'}
        request(app)
            .post('/api/users')
            .set('Content-Type', 'application/json')
            .send(data)
            .expect(403)
            .end (err, res) ->
                if err
                    done(err)
                else
                    conn.count('users').then (count) ->
                        assert.equal count, 0
                        done()

    it 'responds with a 403 for create auth function false', (done) ->
        app.use '/api', flip.api conn,
            users:
                auth:
                    create: -> false
                schema:
                    name: types.String
        data = {_id:1, name:'admin2'}
        request(app)
            .post('/api/users')
            .set('Content-Type', 'application/json')
            .send(data)
            .expect(403)
            .end (err, res) ->
                if err
                    done(err)
                else
                    conn.count('users').then (count) ->
                        assert.equal count, 0
                        done()

    it 'responds with _status=ERR for wrong data types', (done) ->
        app.use '/api', flip.api conn,
            users:
                eid: types.Integer
        data = {eid:'admin2'}
        request(app)
            .post('/api/users')
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
                    conn.count('users').then (count) ->
                        assert.equal count, 0
                        done()

    it 'emits an event on creation', (done) ->
        api = flip.api conn,
            users:
                name: types.String
        app.use '/api', api
        data = {name:'admin2'}
        tests = {}
        [
            'create.pre'
            'users.create.pre'
        ].forEach (x) ->
            tests[x] = false
            api.events.on x, (req, res) ->
                assert.equal req.collection, 'users'
                assert.deepEqual req.body, {name:'admin2'}
                tests[x] = true
        [
            'create.post'
            'users.create.post'
        ].forEach (x) ->
            tests[x] = false
            api.events.on x, (req, res) ->
                assert.equal req.collection, 'users'
                assert.deepEqual res.body,
                    _status: 'OK'
                    _item:
                        _id:1
                        _auth:
                            _edit: true
                            _delete: true
                        name: 'admin2'
                tests[x] = true
        request(app)
            .post('/api/users')
            .set('Content-Type', 'application/json')
            .send(data)
            .expect('Content-Type', /json/)
            .expect(200)
            .end (err, res) ->
                if err
                    done(err)
                else
                    assert.deepEqual tests,
                        'create.pre': true
                        'users.create.pre': true
                        'create.post': true
                        'users.create.post': true
                    assert.deepEqual res.body,
                        _status: 'OK'
                        _item:
                            _id:1
                            _auth:
                                _edit: true
                                _delete: true
                            name: 'admin2'
                    conn.findOne('users', {_id:1}).then (doc) ->
                        assert.deepEqual doc,
                            _id:1
                            name: 'admin2'
                        done()

    it 'handles an Auto function error', (done) ->
        app.use '/api', flip.api conn,
            users:
                name: types.String
                fullName:
                    type: types.Auto
                    auto: (el) -> el.bob[0]
        data = {name:'admin2'}
        request(app)
            .post('/api/users')
            .set('Content-Type', 'application/json')
            .send(data)
            .expect('Content-Type', /json/)
            .expect(500)
            .end (err, res) ->
                if err
                    done(err)
                else
                    assert.equal res.body._status, 'ERR'
                    assert.equal res.body._code, 500
                    assert.isAbove res.body._detail.length, 0
                    done()

    it 'inserts nulls into blank properties', (done) ->
        app.use '/api', flip.api conn,
            users:
                name: types.String
                age: types.Integer
        data = {name:'admin2'}
        request(app)
            .post('/api/users')
            .set('Content-Type', 'application/json')
            .send(data)
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
                            name: 'admin2'
                            age: null
                    conn.findOne('users', {_id:1}).then (doc) ->
                        assert.deepEqual doc,
                            _id:1
                            name: 'admin2'
                            age: null
                        done()
                        
    it 'handles defaults', (done) ->
        app.use '/api', flip.api conn,
            users:
                name: types.String
                age:
                    type: types.Integer
                    default: 32
        data = {name:'admin2'}
        request(app)
            .post('/api/users')
            .set('Content-Type', 'application/json')
            .send(data)
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
                            name: 'admin2'
                            age: 32
                    conn.findOne('users', {_id:1}).then (doc) ->
                        assert.deepEqual doc,
                            _id:1
                            name: 'admin2'
                            age: 32
                        done()