assert = require('assert')
mg = require('mongoose')
assert2 = require('chai').assert
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
            assert2.equal inst.name, '2'
            assert2.notStrictEqual inst.name, 2

        it 'validates number', ->
            inst = new @model(
                number: 'hj'
            )
            inst.save (err, item, nAff) ->
                assert2.notStrictEqual err, null
                assert2.equal err.path, 'number'

        it 'validates boolean', ->
            inst = new @model(
                living: 'hj'
            )
            assert2.isTrue inst.living
            assert2.notStrictEqual inst.living, 'hj'
            inst = new @model(
                living: ''
            )
            assert2.isFalse inst.living
            assert2.notStrictEqual inst.living, ''

        it 'validates date', ->
            inst = new @model(
                updated: '1/1/2014'
            )
            assert2.equal inst.updated.getTime(), new Date(2014,0,1).getTime()


    describe 'advanced schema functions', ->
        beforeEach (done) ->
            schema = require('./lib/advSchema')
            @model = fnModel.model('advModel', schema)
            @model.remove {}, (err) -> done()
            
        it 'performs auto function', (done) ->
            inst = new @model(
                name: 'bob'
            )
            inst.save (err, item, nAff) ->
                assert2.equal err, null
                assert2.equal item.auto, 'BOB'
                inst.name = 'fred'
                inst.save (err, item, nAff) ->
                    assert2.equal err, null
                    assert2.equal item.auto, 'FRED'
                    done()
    
        it 'performs auto init function', (done) ->
            inst = new @model(
                name: 'bob'
            )
            inst.save (err, item, nAff) ->
                assert2.equal err, null
                assert2.equal item.auto_init, 'BOB'
                inst.name = 'fred'
                inst.save (err, item, nAff) ->
                    assert2.equal err, null
                    assert2.equal item.auto_init, 'BOB'
                    done()
    
        it 'performs subdoc auto & auto init functions', (done) ->
            inst = new @model(
                name: 'bob'
                subdoc:
                    name: 'fred'
            )
            inst.save (err, item, nAff) ->
                assert2.equal err, null
                assert2.equal item.subdoc.auto, 'FRED'
                assert2.equal item.subdoc.auto_init, 'BOB'
                inst.name = 'fred'
                inst.subdoc.name = 'george'
                inst.save (err, item, nAff) ->
                    assert2.equal err, null
                    assert2.equal item.get('subdoc.auto'), 'GEORGE'
                    assert2.equal item.subdoc.auto_init, 'BOB'
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
                assert2.equal err, null
                assert2.equal item.sublist[0].auto, 'FRED'
                assert2.equal item.sublist[0].auto_init, 'BOB'
                assert2.equal item.sublist[1].auto, 'TOM'
                assert2.equal item.sublist[1].auto_init, 'BOB'
                inst.name = 'fred'
                inst.sublist[0].name = 'george'
                inst.sublist[1].name = 'harry'
                inst.save (err, item, nAff) ->
                    assert2.equal err, null
                    assert2.equal item.sublist[0].auto, 'GEORGE'
                    assert2.equal item.sublist[0].auto_init, 'BOB'
                    assert2.equal item.sublist[1].auto, 'HARRY'
                    assert2.equal item.sublist[1].auto_init, 'BOB'
                    done()
