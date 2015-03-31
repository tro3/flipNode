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
        app = express()
        conn = connect('mongodb://localhost:27017/test')
        app.use '/api', flip.api conn,
            users:
                name: types.String
                
    afterEach (done) ->
        conn.drop('users')
        .then -> done()

    it 'responds with a 404 for non-existent collection', (done) ->
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

    it 'responds with a simple list', (done) ->
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

