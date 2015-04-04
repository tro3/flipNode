assert = require('chai').assert
request = require('supertest')
express = require('express')
flip = require('../src')
types = flip.schema.types
connect = require('../src/db').connect



describe 'api.updateItem', ->
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

    it 'updates a simple item', (done) ->
        app.use '/api', flip.api conn,
            users:
                name: types.String
        conn.insert('users', {_id:1, name:'admin'})
        .then ->
            data = {_id:1, name:'admin2'}
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
        .catch (err) -> done(err)
    
    it 'responds with a 404 for non-existent collection', (done) ->
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
                        conn.findOne('users', {_id:1}).then (doc) ->
                            assert.deepEqual doc,
                                _id:1
                                name: 'admin'            
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
                .put('/api/users/2')
                .set('Content-Type', 'application/json')
                .send(data)
                .expect(404)
                .end (err, res) ->
                    if err
                        done(err)
                    else
                        conn.findOne('users', {_id:1}).then (doc) ->
                            assert.deepEqual doc,
                                _id:1
                                name: 'admin'            
                            done()
        .catch (err) -> done(err)

    it 'responds with a 400 for for mismatched id', (done) ->
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
                        conn.findOne('users', {_id:1}).then (doc) ->
                            assert.deepEqual doc,
                                _id:1
                                name: 'admin'            
                            done()
        .catch (err) -> done(err)

    it 'responds with a 400 for for garbled data', (done) ->
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
                        conn.findOne('users', {_id:1}).then (doc) ->
                            assert.deepEqual doc,
                                _id:1
                                name: 'admin'            
                            done()
        .catch (err) -> done(err)

    it 'responds with a 403 for edit auth constant false', (done) ->
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
                        conn.findOne('users', {_id:1}).then (doc) ->
                            assert.deepEqual doc,
                                _id:1
                                name: 'admin'            
                            done()
        .catch (err) -> done(err)

    it 'responds with a 403 for edit auth function false', (done) ->
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
                        conn.findOne('users', {_id:1}).then (doc) ->
                            assert.deepEqual doc,
                                _id:1
                                name: 'admin'            
                            done()
        .catch (err) -> done(err)
    
    it 'responds with _status=ERR for wrong data types', (done) ->
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
                        conn.findOne('users', {_id:1}).then (doc) ->
                            assert.deepEqual doc,
                                _id:1
                                eid: 408            
                            done()
        .catch (err) -> done(err)