assert = require('chai').assert
request = require('supertest')
express = require('express')
flip = require('../src')
types = flip.schema.types
connect = require('../src/db').connect



describe 'api.getList', ->
    app = null
    conn = null
    
    before ->
        conn = connect('mongodb://localhost:27017/test')
                
    afterEach (done) ->
        conn.drop('users')
        .finally -> done()

    it 'responds with a simple list', (done) ->
        app = express()
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

    it 'handles a list retrieval with a query'

    it 'handles a list retrieval with a subset of fields'

    it 'handles a list retrieval with a sort request'

    it 'handles a list retrieval with a page request'