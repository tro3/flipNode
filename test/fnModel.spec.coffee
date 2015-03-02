mg = require('mongoose')
assert = require('chai').assert
fnModel = require('../src/fnModel')      


describe 'fnModel', ->
    before -> mg.connect('mongodb://localhost/test')
    after  -> mg.disconnect()

    describe 'basic data type validation', ->
        beforeEach (done) ->
            schema = require('./lib/basicSchema')
            @model = fnModel.model('Model', schema)
            @model.remove {}, (err) -> done()
            
        it 'validates string', ->
            inst = new @model(
                name: 2
            )
            assert.equal inst.name, '2'
            assert.notStrictEqual inst.name, 2

        it 'validates number', ->
            inst = new @model(
                number: 'hj'
            )
            inst.save (err, item, nAff) ->
                assert.notStrictEqual err, null
                assert.equal err.path, 'number'

        it 'validates boolean', ->
            inst = new @model(
                living: 'hj'
            )
            assert.isTrue inst.living
            assert.notStrictEqual inst.living, 'hj'
            inst = new @model(
                living: ''
            )
            assert.isFalse inst.living
            assert.notStrictEqual inst.living, ''

        it 'validates date', ->
            inst = new @model(
                updated: '1/1/2014'
            )
            assert.equal inst.updated.getTime(), new Date(2014,0,1).getTime()


    describe 'schema behaviors', ->
        beforeEach (done) ->
            schema = require('./lib/advSchema')
            @model = fnModel.model('advModel', schema)
            @model.remove {}, (err) -> done()

        it 'performs serialize function', () ->
            inst = new @model(
                name: 'bob'
                sublist: [{
                    name: 'fred'
                },{
                    name: 'tom'
                }]
            )
            assert.equal inst.capname, 'BOB'

        it 'validates required', (done) ->
            inst = new @model(
                sublist: [{
                    name: 'fred'
                },{
                    name: 'tom'
                }]
            )
            inst.save (err, item, nAff) ->
                assert.notStrictEqual err, null
                assert.property err.errors, 'name'
                done()

        it 'validates unique', (done) ->
            i1 = new @model(
                name: 'bob'
                eid: 12345
            )
            i1.save()
            
            @model.on('error', -> )
            inst = new @model(
                name: 'fred'
                eid: 12345
            )
            inst.save (err, item, nAff) ->
                assert.notStrictEqual err, null
                assert.property err.errors, 'eid'
                assert.equal err.errors.eid, '12345 is not unique'                
                done()

        it 'performs default', (done) ->
            inst = new @model(
                name: 'bob'
            )
            inst.save (err, item, nAff) ->
                assert.strictEqual err, null
                assert.property item.subdoc, 'name'
                assert.equal item.subdoc.name, 'fred'
                done()

        it 'removes extraneous data', (done) ->
            inst = new @model(
                name: 'bob'
                last_name: 'george'
                sublist: [{
                    name: 'fred'
                },{
                    name: 'tom'
                }]
            )
            inst.save (err, item, nAff) ->
                assert.strictEqual err, null
                assert.property item, 'name'
                assert.property item, 'sublist'
                assert.notProperty item, 'last_name'
                done()

        it 'validates dynamic Allowed', (done) ->
            inst = new @model(
                name: 'bob'
                stage: 'Closed'
            ) 
            inst.save (err, item, nAff) ->
                assert.notStrictEqual err, null
                inst.stage = 'Open'
                inst.save (err, item, nAff) ->
                    assert.strictEqual err, null
                    item.save (err, item, nAff) ->
                        assert.strictEqual err, null
                        item.stage = 'Fred'
                        item.save (err, item2, nAff) ->
                            assert.notStrictEqual err, null
                            item.stage = 'Closed'
                            item.save (err, item, nAff) ->
                                assert.strictEqual err, null
                                done()
            

    describe 'schema auto functions', ->
        beforeEach (done) ->
            schema = require('./lib/advSchema')
            @model = fnModel.model('advModel', schema)
            @model.remove {}, (err) -> done()
            
        it 'performs auto function', (done) ->
            inst = new @model(
                name: 'bob'
            )
            inst.save (err, item, nAff) ->
                assert.equal err, null
                assert.equal item.auto, 'BOB'
                inst.name = 'fred'
                inst.save (err, item, nAff) ->
                    assert.equal err, null
                    assert.equal item.auto, 'FRED'
                    done()
    
        it 'performs auto init function', (done) ->
            inst = new @model(
                name: 'bob'
            )
            inst.save (err, item, nAff) ->
                assert.equal err, null
                assert.equal item.auto_init, 'BOB'
                inst.name = 'fred'
                inst.save (err, item, nAff) ->
                    assert.equal err, null
                    assert.equal item.auto_init, 'BOB'
                    done()
    
        it 'performs subdoc auto & auto init functions', (done) ->
            inst = new @model(
                name: 'bob'
                subdoc:
                    name: 'fred'
            )
            inst.save (err, item, nAff) ->
                assert.equal err, null
                assert.equal item.subdoc.auto, 'FRED'
                assert.equal item.subdoc.auto_init, 'BOB'
                inst.name = 'fred'
                inst.subdoc.name = 'george'
                inst.save (err, item, nAff) ->
                    assert.equal err, null
                    assert.equal item.get('subdoc.auto'), 'GEORGE'
                    assert.equal item.subdoc.auto_init, 'BOB'
                    done()
    
        it 'performs sublist auto & auto init functions', (done) ->
            inst = new @model(
                name: 'bob'
                sublist: [{
                    name: 'fred'
                },{
                    name: 'tom'
                }]
            )
            inst.save (err, item, nAff) ->
                assert.equal err, null
                assert.equal item.sublist[0].auto, 'FRED'
                assert.equal item.sublist[0].auto_init, 'BOB'
                assert.equal item.sublist[1].auto, 'TOM'
                assert.equal item.sublist[1].auto_init, 'BOB'
                inst.name = 'fred'
                inst.sublist[0].name = 'george'
                inst.sublist[1].name = 'harry'
                inst.save (err, item, nAff) ->
                    assert.equal err, null
                    assert.equal item.sublist[0].auto, 'GEORGE'
                    assert.equal item.sublist[0].auto_init, 'BOB'
                    assert.equal item.sublist[1].auto, 'HARRY'
                    assert.equal item.sublist[1].auto_init, 'BOB'
                    done()

