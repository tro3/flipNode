assert = require('chai').assert
request = require('supertest')
express = require('express')
flip = require('../src')
types = flip.schema.types
connect = require('../src/api/db').connect

List = types.List
Doc = types.Doc
Auto = types.Auto
AutoInit = types.AutoInit
String = types.String
Integer = types.Integer
Float = types.Float
Reference = types.Reference
Date = types.Date
Boolean = types.Boolean
ReqString = {type: String, required: true}

p = console.log


describe 'api specific test cases', ->
    app = null
    conn = null

    before ->
        conn = connect('mongodb://localhost:27017/test')

    beforeEach ->
        app = express()

    afterEach (done) ->
        conn.drop('users')
        .finally -> conn.drop('test')
        .finally -> conn.drop('flipData.history')
        .finally -> done()

    it 'handles Object.keys issue', (done) ->
        app.use '/api', flip.api conn,
            users:
                username: ReqString
                firstName: String
                lastName: String
                fullName: {type: Auto, auto: (el) -> "#{el.firstName} #{el.lastName}"}
                    
            test:
                description: ReqString
                assignee:
                    type: Reference
                    collection: 'users'
                    fields: ['fullName']
                complete: {type: Boolean, default: false}
        conn.insert('test', {
            _id: 1
            description: 'Brush teeth'
            assignee: null
            complete: false
        })
        .then ->
            data =
                _id: 1
                description: 'Brush teeth'
                assignee: null
            request(app)
                .put('/api/test/1')
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
                                description: 'Brush teeth'
                                assignee: null
                                complete: false
                        conn.findOne('test', {_id:1}).then (doc) ->
                            assert.deepEqual doc,
                                _id:1
                                description: 'Brush teeth'
                                assignee: null
                                complete: false
                            done()
        .catch (err) -> done(err)
    
