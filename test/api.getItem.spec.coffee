assert = require('chai').assert
request = require('supertest')
express = require('express')
flip = require('../src')
types = flip.schema.types
connect = require('../src/db').connect



describe 'api.getItem', ->
    app = null
    conn = null
    
    before ->
        conn = connect('mongodb://localhost:27017/test')
                
    afterEach (done) ->
        conn.drop('users')
        .finally -> done()

    it 'responds with a simple item', (done) ->
        app = express()
        app.use '/api', flip.api conn,
            users:
                name: types.String
        conn.insert('users', {_id:1, name:'admin'})
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
                .get('/api/frogs/1')
                .expect(404)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        done()
        .catch (err) -> done(err)

    it.skip 'responds with a 404 for non-existent document'

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
                .get('/api/users/1')
                .expect(403)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        done()
        .catch (err) -> done(err)

    it 'responds with a 403 for read auth function false', (done) ->
        app = express()
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

    it 'handles a simple item with a subset of fields'