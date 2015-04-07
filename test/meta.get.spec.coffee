assert = require('chai').assert
request = require('supertest')
express = require('express')
flip = require('../src')
types = flip.schema.types

p = console.log


describe 'meta API', ->
    app = null
    conn = null

    beforeEach ->
        app = express()

    it 'responds with a simple endpoint config', (done) ->
        api = flip.api null,
            users:
                name: types.String
        app.use '/api', api
        app.use '/meta', flip.meta api
        request(app)
            .get('/meta')
            .expect('Content-Type', /json/)
            .expect(200)
            .end (err, res) ->
                if err
                    done(err)
                else
                    assert.deepEqual res.body,
                        users:
                            _id:
                                type: 'Integer'
                            name:
                                type: 'String'
                    done()

    it 'responds with a simple complex endpoint config', (done) ->
        api = flip.api null,
            users:
                name: types.String
                nested:
                    name: types.String
                    docList: [
                        name: types.String
                    ]
                docList: [
                    name: types.String
                    nested:
                        docList: [
                            name: types.String
                        ]
                ]

        app.use '/api', api
        app.use '/meta', flip.meta api
        request(app)
            .get('/meta')
            .expect('Content-Type', /json/)
            .expect(200)
            .end (err, res) ->
                if err
                    done(err)
                else
                    assert.deepEqual res.body,
                        users:
                            _id:
                                type: 'Integer'
                            name:
                                type: 'String'
                            nested:
                                type: 'Doc'
                                schema:
                                    _id:
                                        type: 'Integer'
                                    name:
                                        type: 'String'
                                    docList:
                                        type: 'List'
                                        schema:
                                            _id:
                                                type: 'Integer'
                                            name:
                                                type: 'String'
                            docList:
                                type: 'List'
                                schema:
                                    _id:
                                        type: 'Integer'
                                    name:
                                        type: 'String'
                                    nested:
                                        type: 'Doc'
                                        schema:
                                            _id:
                                                type: 'Integer'
                                            docList:
                                                type: 'List'
                                                schema:
                                                    _id:
                                                        type: 'Integer'
                                                    name:
                                                        type: 'String'
                    done()

    it 'converts all basic data types', (done) ->
        api = flip.api null,
            users:
                str: types.String
                int: types.Integer
                flt: types.Float
                ref:
                    type: types.Reference
                    collection: 'refs'
                    fields: ['name', 'city']
                date: types.Date
                bool: types.Boolean

        app.use '/api', api
        app.use '/meta', flip.meta api
        request(app)
            .get('/meta')
            .expect('Content-Type', /json/)
            .expect(200)
            .end (err, res) ->
                if err
                    done(err)
                else
                    assert.deepEqual res.body,
                        users:
                            _id:
                                type: 'Integer'
                            str:
                                type: 'String'
                            int:
                                type: 'Integer'
                            flt:
                                type: 'Float'
                            ref:
                                type: 'Reference'
                                collection: 'refs'
                                fields: ['name', 'city']
                            date:
                                type: 'Date'
                            bool:
                                type: 'Boolean'
                    done()

    it 'marks required types', (done) ->
        api = flip.api null,
            users:
                name:
                    type: types.String
                    required: true
        app.use '/api', api
        app.use '/meta', flip.meta api
        request(app)
            .get('/meta')
            .expect('Content-Type', /json/)
            .expect(200)
            .end (err, res) ->
                if err
                    done(err)
                else
                    assert.deepEqual res.body,
                        users:
                            _id:
                                type: 'Integer'
                            name:
                                type: 'String'
                                required: true
                    done()
                    
    it 'marks unique types', (done) ->
        api = flip.api null,
            users:
                name:
                    type: types.String
                    unique: true
        app.use '/api', api
        app.use '/meta', flip.meta api
        request(app)
            .get('/meta')
            .expect('Content-Type', /json/)
            .expect(200)
            .end (err, res) ->
                if err
                    done(err)
                else
                    assert.deepEqual res.body,
                        users:
                            _id:
                                type: 'Integer'
                            name:
                                type: 'String'
                                unique: true
                    done()
                    
    it 'marks Auto functions', (done) ->
        api = flip.api null,
            users:
                name:
                    type: types.Auto
                    auto: -> 1
                name2:
                    type: types.AutoInit
                    auto: -> 1
        app.use '/api', api
        app.use '/meta', flip.meta api
        request(app)
            .get('/meta')
            .expect('Content-Type', /json/)
            .expect(200)
            .end (err, res) ->
                if err
                    done(err)
                else
                    assert.deepEqual res.body,
                        users:
                            _id:
                                type: 'Integer'
                            name:
                                type: 'Auto'
                            name2:
                                type: 'Auto'
                    done()
                    
    it 'converts Allowed values', (done) ->
        api = flip.api null,
            users:
                name:
                    type: types.Integer
                    allowed: [1,2]
        app.use '/api', api
        app.use '/meta', flip.meta api
        request(app)
            .get('/meta')
            .expect('Content-Type', /json/)
            .expect(200)
            .end (err, res) ->
                if err
                    done(err)
                else
                    assert.deepEqual res.body,
                        users:
                            _id:
                                type: 'Integer'
                            name:
                                type: 'Integer'
                                allowed: [1,2]
                    done()

    it.skip 'converts Allowed functions', (done) ->
        api = flip.api null,
            users:
                name:
                    type: types.Integer
                    allowed: (el) -> [1,2]
        app.use '/api', api
        app.use '/meta', flip.meta api
        request(app)
            .get('/meta')
            .expect('Content-Type', /json/)
            .expect(200)
            .end (err, res) ->
                if err
                    done(err)
                else
                    assert.deepEqual res.body,
                        users:
                            _id:
                                type: 'Integer'
                            name:
                                type: 'Integer'
                                allowed: '(el) -> [1,2]'
                    done()
