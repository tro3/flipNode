assert = require('chai').assert
request = require('supertest')
express = require('express')
flip = require('../src')
types = flip.schema.types
connect = require('../src/api/db').connect



describe 'api.getList', ->
    app = null
    conn = null

    before ->
        conn = connect('mongodb://localhost:27017/test')

    beforeEach ->
        app = express()

    afterEach (done) ->
        conn.drop('users')
        .finally -> done()

    it 'responds with a simple list', (done) ->
        app.use '/api', flip.api conn,
            users:
                name: types.String
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            request(app)
                .get('/api/users')
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        assert.deepEqual res.body,
                            _status: 'OK'
                            _auth: true
                            _items: [{
                                _id:1
                                _auth:
                                    _edit: true
                                    _delete: true
                                name: 'admin'
                            }]
                        done()
        .catch (err) -> done(err)

    it 'responds with a simple list create auth constant false', (done) ->
        app = express()
        app.use '/api', flip.api conn,
            users:
                auth:
                    create: false
                schema:
                    name: types.String
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            request(app)
                .get('/api/users')
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        assert.deepEqual res.body,
                            _status: 'OK'
                            _auth: false
                            _items: [{
                                _id:1
                                _auth:
                                    _edit: true
                                    _delete: true
                                name: 'admin'
                            }]
                        done()
        .catch (err) -> done(err)

    it 'responds with a simple list create auth function false', (done) ->
        app = express()
        app.use '/api', flip.api conn,
            users:
                auth:
                    create: -> false
                schema:
                    name: types.String
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            request(app)
                .get('/api/users')
                #.expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        assert.deepEqual res.body,
                            _status: 'OK'
                            _auth: false
                            _items: [{
                                _id:1
                                _auth:
                                    _edit: true
                                    _delete: true
                                name: 'admin'
                            }]
                        done()
        .catch (err) -> done(err)

    it 'responds with a 404 for non-existent collection', (done) ->
        app = express()
        app.use '/api', flip.api conn,
            users:
                name: types.String
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            request(app)
                .get('/api/frogs')
                .expect(404)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        done()
        .catch (err) -> done(err)

    it 'responds with a 403 for read auth constant false', (done) ->
        app = express()
        app.use '/api', flip.api conn,
            users:
                auth:
                    read: false
                schema:
                    name: types.String
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            request(app)
                .get('/api/users')
                .expect(403)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        done()
        .catch (err) -> done(err)

    it 'does not respond with a 403 for read auth function false', (done) ->
        app = express()
        app.use '/api', flip.api conn,
            users:
                auth:
                    read: -> false
                schema:
                    name: types.String
        conn.insert('users', [{_id:1, name:'admin'}, {_id:2, name:'bob'}])
        .then ->
            request(app)
                .get('/api/users')
                .expect(200)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        assert.deepEqual res.body,
                            _status: 'OK'
                            _auth: true
                            _items: []
                        done()
        .catch (err) -> done(err)

    it 'handles a list retrieval with a query', (done) ->
        app = express()
        app.use '/api', flip.api conn,
            users:
                name: types.String
        conn.insert('users', [
            {_id:1, name:'admin', city:'Menlo Park'}
            {_id:2, name:'bob', city:'Palo Alto'}
        ])
        .then ->
            request(app)
                .get('/api/users?query={"city":"Palo Alto"}')
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        assert.deepEqual res.body,
                            _status: 'OK'
                            _auth: true
                            _items: [{
                                _id:2
                                _auth:
                                    _edit: true
                                    _delete: true
                                name:'bob'
                                city:'Palo Alto'
                            }]
                        done()
        .catch (err) -> done(err)

    it 'handles a list retrieval with a subset of fields', (done) ->
        app = express()
        app.use '/api', flip.api conn,
            users:
                name: types.String
        conn.insert('users', {_id:1, name:'admin', city:'Menlo Park'})
        .then ->
            request(app)
                .get('/api/users?fields={"city":1}')
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        assert.deepEqual res.body,
                            _status: 'OK'
                            _auth: true
                            _items: [{
                                _id:1
                                _auth:
                                    _edit: true
                                    _delete: true
                                city: 'Menlo Park'
                            }]
                        done()
        .catch (err) -> done(err)

    it 'handles a list retrieval with a sort request', (done) ->
        app = express()
        app.use '/api', flip.api conn,
            users:
                name: types.String
        conn.insert('users', [
            {_id:1, name:'admin', city:'Menlo Park'}
            {_id:2, name:'bob', city:'Palo Alto'}
        ])
        .then ->
            request(app)
                .get('/api/users?sort={"_id":-1}')
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        assert.deepEqual res.body,
                            _status: 'OK'
                            _auth: true
                            _items: [{
                                _id:2
                                _auth:
                                    _edit: true
                                    _delete: true
                                name:'bob'
                                city:'Palo Alto'
                            },{
                                _id:1
                                _auth:
                                    _edit: true
                                    _delete: true
                                name:'admin'
                                city:'Menlo Park'
                            }]
                        done()
        .catch (err) -> done(err)

    it 'handles a list retrieval with a page request', (done) ->
        app = express()
        app.use '/api', flip.api conn,
            users:
                name: types.String
        conn.insert('users', [
            {_id:1, name:'admin', city:'Menlo Park'}
            {_id:2, name:'bob', city:'Palo Alto'}
            {_id:3, name:'fred', city:'San Jose'}
        ])
        .then ->
            request(app)
                .get('/api/users?sort={"_id":1}&pageSize=2&page=1')
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        assert.deepEqual res.body,
                            _status: 'OK'
                            _auth: true
                            _page: 1
                            _pages: 2
                            _items: [{
                                _id:1
                                _auth:
                                    _edit: true
                                    _delete: true
                                name:'admin'
                                city:'Menlo Park'
                            },{
                                _id:2
                                _auth:
                                    _edit: true
                                    _delete: true
                                name:'bob'
                                city:'Palo Alto'
                            }]
        .then ->
            request(app)
                .get('/api/users?sort={"_id":1}&pageSize=2&page=2')
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        assert.deepEqual res.body,
                            _status: 'OK'
                            _auth: true
                            _page: 2
                            _pages: 2
                            _items: [{
                                _id:3
                                _auth:
                                    _edit: true
                                    _delete: true
                                name:'fred'
                                city:'San Jose'
                            }]
                        done()
        .catch (err) -> done(err)
        
    it 'emits an event on read list', (done) ->
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
                assert.equal req.id, undefined
                tests[x] = true
        [
            'post'
            'read.post'
            'users.read.post'
        ].forEach (x) ->
            tests[x] = false
            api.events.on x, (req, res) ->
                assert.equal req.collection, 'users'
                assert.equal req.id, undefined
                assert.deepEqual res.body,
                    _status: 'OK'
                    _auth: true
                    _items: [{
                        _id:1
                        _auth:
                            _edit: true
                            _delete: true
                        name: 'admin'
                    }]
                tests[x] = true
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            request(app)
                .get('/api/users')
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
                            _auth: true
                            _items: [{
                                _id:1
                                _auth:
                                    _edit: true
                                    _delete: true
                                name: 'admin'
                            }]
                        done()
        .catch (err) -> done(err)
