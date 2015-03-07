assert = require('chai').assert
p = console.log

schema = require('../src/schema')
Schema = schema.Schema
String =  schema.types.String
Dict = schema.types.Dict
List = schema.types.List
Auth = require('../src/auth')
AuthProto = new Auth({schema:{}}).__proto__


describe 'Auth module', ->

    describe 'new Auth function', ->
        it 'handles flat object default', ->
            endpoint =
                schema:
                    name: String
            assert.deepEqual new Auth(endpoint), {
                __proto__: AuthProto
                create: true
                read: true
                edit: true
                delete: true
                __proto__: AuthProto
            }

        it 'handles flat object with constant', ->
            endpoint =
                auth:
                    delete: false
                schema:
                    name: String
            assert.deepEqual new Auth(endpoint), {
                __proto__: AuthProto
                create: true
                read: true
                edit: true
                delete: false
            }

        it 'handles flat object with function', ->
            endpoint =
                auth:
                    edit: () -> false
                schema:
                    name: String
            assert.deepEqual new Auth(endpoint), {
                __proto__: AuthProto
                create: true
                read: true
                edit: false
                delete: true
            }

        it 'handles nested object', ->
            endpoint =
                auth:
                    edit: (el) -> el.x
                schema:
                    name: String
                    subdoc1:
                        type: Dict
                        auth:
                            create: false
                        schema:
                            name: String
                    subdoc2:
                        type: Dict
                        schema:
                            name: String
            assert.deepEqual new Auth(endpoint, {x:false}), {
                __proto__: AuthProto
                create: true
                read: true
                edit: false
                delete: true
                children:
                    subdoc1: {create: false, read: true, edit: false, delete: true}
                    subdoc2: {create: true, read: true, edit: false, delete: true}
            }

        it 'handles lists of nested objects', ->
            user_test = 0
            db_test = 0
            root_test = 0
            endpoint =
                auth:
                    edit: (el, root, user, db) ->
                        root_test = root.x
                        user_test = user
                        db_test = db
                        el.x
                schema:
                    list:
                        type: List
                        schema:
                            name: String
                            subdoc:
                                type: Dict
                                auth:
                                    read: (el) -> el.name == '1'
                                schema:
                                    name: String
            assert.deepEqual new Auth(endpoint, {x:false, list:[{subdoc:{name:'1'}},{subdoc:{name:'2'}}]}, 1, 2), {
                __proto__: AuthProto
                create: true
                read: true
                edit: false
                delete: true
                children:
                    list: [{
                        create: true
                        read: true
                        edit: false
                        delete: true
                        children:
                            subdoc: {create: true, read: true, edit: false, delete: true}
                    },{
                        create: true
                        read: true
                        edit: false
                        delete: true
                        children:
                            subdoc: {create: true, read: false, edit: false, delete: true}
                    }]
            }
            assert.equal root_test, false
            assert.equal user_test, 1
            assert.equal db_test, 2

    describe 'Auth object', ->
        it "gets root permissions", ->
            endpoint =
                auth:
                    edit: () -> false
                schema:
                    name: String
            auth = new Auth(endpoint)
            assert.deepEqual auth.get(), {
                create: true
                read: true
                edit: false
                delete: true
            }

        it "gets top object permissions", ->
            endpoint =
                auth:
                    edit: () -> false
                schema:
                    name: String
                    subdoc:
                        type: Dict
                        auth:
                            read: false
                        schema:
                            name: String

            auth = new Auth(endpoint)
            assert.deepEqual auth.get('subdoc'), {
                create: true
                read: false
                edit: false
                delete: true
            }

        it "gets nested object permissions", ->
            endpoint =
                auth:
                    edit: () -> false
                schema:
                    name: String
                    subdoc:
                        type: Dict
                        schema:
                            name: String
                            subdoc:
                                type: Dict
                                auth:
                                    read: false
                                schema:
                                    name: String

            auth = new Auth(endpoint)
            assert.deepEqual auth.get('subdoc.subdoc'), {
                create: true
                read: false
                edit: false
                delete: true
            }

        it "gets top list object permissions", ->
            endpoint =
                auth:
                    edit: () -> false
                schema:
                    list:
                        type: List
                        auth:
                            read: (el) -> el.name == 'b'
                        schema:
                            name: String

            auth = new Auth(endpoint, {list: [{name:'a'}, {name:'b'}]})
            assert.deepEqual auth.get('list.0'), {
                create: true
                read: false
                edit: false
                delete: true
            }
            assert.deepEqual auth.get('list.1'), {
                create: true
                read: true
                edit: false
                delete: true
            }

        it "gets permissions from lists of nested objects", ->
            endpoint =
                auth:
                    edit: () -> false
                schema:
                    list:
                        type: List
                        auth:
                            read: (el) -> el.name == 'b'
                        schema:
                            name: String
                            subdoc:
                                type: Dict
                                auth:
                                    delete: false
                                schema:
                                    name: String

            auth = new Auth(endpoint, {list: [{name:'a'}, {name:'b'}]})
            assert.deepEqual auth.get('list.0.subdoc'), {
                create: true
                read: false
                edit: false
                delete: false
            }
            assert.deepEqual auth.get('list.1.subdoc'), {
                create: true
                read: true
                edit: false
                delete: false
            }