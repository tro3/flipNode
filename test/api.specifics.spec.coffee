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
    

    it 'handles total schema shift', (done) ->
        
        all = 
            str:String
            int:Integer
            flt:Float
            ref:
                type: Reference
                collection: 'users'
            date:Date
            bool:Boolean

        app.use '/api', flip.api conn,
            users:
                name: String
            test:
                a: all
        conn.insert('test', {
            _id: 1
            b:
                str:'hi'
                int:1
                flt:1.2
                ref:1
                date:new Date('2/1/2005')
                bool:true
        })
        .then ->
            request(app)
                .put('/api/test/1')
                .set('Content-Type', 'application/json')
                .send({_id:1})
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
                                a:
                                    _id:1
                                    _auth:
                                        _edit: true
                                    str:null
                                    int:null
                                    flt:null
                                    ref:null
                                    date:null
                                    bool:null
                        conn.findOne('test', {_id:1}).then (doc) ->
                            assert.deepEqual doc,
                                _id:1
                                a:
                                    _id:1
                                    str:null
                                    int:null
                                    flt:null
                                    ref:null
                                    date:null
                                    bool:null
                            done()
        .catch (err) -> done(err)


    it 'handles list of objects added to schema', (done) ->
        
        all =
            name: String
            description: String
            lastFunding: String
            monthsSince: Integer
            notes: [
                markdown: String
                creationDate:
                    type: AutoInit
                    auto: (el) -> new Date()
            ]

        app.use '/api', flip.api conn,
            users:
                name: String
            test: all
        conn.insert('test', {
            _id: 1
            name: "Bobsam"
            description: null
            lastFunding: "None"
            monthsSince: null
        })
        .then ->
            request(app)
                .put('/api/test/1')
                .set('Content-Type', 'application/json')
                .send({_id:1})
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
                                    notes: true
                                name: "Bobsam"
                                description: null
                                lastFunding: "None"
                                monthsSince: null
                                notes: []
                        conn.findOne('test', {_id:1}).then (doc) ->
                            assert.deepEqual doc,
                                _id:1
                                name: "Bobsam"
                                description: null
                                lastFunding: "None"
                                monthsSince: null
                                notes: []
                            done()
        .catch (err) -> done(err)



    it 'handles Date serialization', (done) ->
        
        all = 
            str:String
            date:Date

        app.use '/api', flip.api conn,
            test:
                a: all
        conn.insert('test', {
            _id: 1
            a:
                _id: 1
                str:'hi'
                date:new Date('2/1/2005')
        })
        .then ->
            conn.findOne('test', {_id:1})
        .then (doc) ->
            assert.deepEqual doc,
                _id:1
                a:
                    _id: 1
                    str: 'hi'
                    date: new Date('2/1/2005')
        .then ->
            request(app)
                .get('/api/test/1')
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
                                a:
                                    _id:1
                                    _auth:
                                        _edit: true
                                    str:'hi'
                                    date:new Date('2/1/2005').toISOString()
                        done()
        .catch (err) -> done(err)
