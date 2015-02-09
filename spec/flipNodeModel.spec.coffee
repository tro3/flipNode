flipNode = require('../src')

model = (name, schema) -> flipNode.model(name, schema)


describe 'flipNodeDoc', ->
    beforeEach -> flipNode.connect('mongodb://localhost/test')
    afterEach  -> flipNode.disconnect()

    describe 'basic data type validation', ->
        beforeEach (done) ->
            schema = require('./lib/basicSchema')
            @Model = model('Model', schema)
            @Model.remove {}, (err) -> done()
            
        it 'validates string', (done) ->
            inst = new @Model(
                name: 2
            )
            expect(inst.name).toBe('2')
            expect(inst.name).not.toBe(2)
            done()

        it 'validates number', (done) ->
            inst = new @Model(
                number: 'hj'
            )
            inst.save (err, item, nAff) ->
                expect(err).not.toBe(null)
                expect(err.path).toBe('number')
                done()

        it 'validates boolean', (done) ->
            inst = new @Model(
                living: 'hj'
            )
            expect(inst.living).toBe(true)
            expect(inst.living).not.toBe('hj')
            inst = new @Model(
                living: ''
            )
            expect(inst.living).toBe(false)
            expect(inst.living).not.toBe('')
            done()

        it 'validates date', (done) ->
            inst = new @Model(
                updated: '1/1/2014'
            )
            expect(inst.updated.getTime()).toBe(new Date(2014,0,1).getTime())
            done()
            

    describe 'advanced schema functions', ->
        beforeEach (done) ->
            schema = require('./lib/advSchema')
            @Model = model('advModel', schema)
            @Model.remove {}, (err) -> done()
            
        it 'performs auto function', (done) ->
            inst = new @Model(
                name: 'bob'
            )
            inst.save (err, item, nAff) ->
                expect(err).toBe(null)
                expect(item.auto).toBe('BOB')
                inst.name = 'fred'
                inst.save (err, item, nAff) ->
                    expect(err).toBe(null)
                    expect(item.auto).toBe('FRED')
                    done()

        it 'performs auto init function', (done) ->
            inst = new @Model(
                name: 'bob'
            )
            inst.save (err, item, nAff) ->
                expect(err).toBe(null)
                expect(item.auto_init).toBe('BOB')
                inst.name = 'fred'
                inst.save (err, item, nAff) ->
                    expect(err).toBe(null)
                    expect(item.auto_init).toBe('BOB')
                    done()

        it 'performs subdoc auto & auto init functions', (done) ->
            inst = new @Model(
                name: 'bob'
                subdoc:
                    name: 'fred'
            )
            inst.save (err, item, nAff) ->
                expect(err).toBe(null)
                expect(item.subdoc.auto).toBe('FRED')
                expect(item.subdoc.auto_init).toBe('BOB')
                inst.name = 'fred'
                inst.subdoc.name = 'george'
                inst.save (err, item, nAff) ->
                    expect(err).toBe(null)
                    expect(item.get('subdoc.auto')).toBe('GEORGE')
                    expect(item.subdoc.auto_init).toBe('BOB')
                    done()

        it 'performs sublist auto & auto init functions', (done) ->
            inst = new @Model(
                name: 'bob'
                sublist: [{
                    name: 'fred'
                },{
                    name: 'tom'
                }]
            )
            inst.save (err, item, nAff) ->
                expect(err).toBe(null)
                expect(item.sublist[0].auto).toBe('FRED')
                expect(item.sublist[0].auto_init).toBe('BOB')
                expect(item.sublist[1].auto).toBe('TOM')
                expect(item.sublist[1].auto_init).toBe('BOB')
                inst.name = 'fred'
                inst.sublist[0].name = 'george'
                inst.sublist[1].name = 'harry'
                inst.save (err, item, nAff) ->
                    expect(err).toBe(null)
                    expect(item.sublist[0].auto).toBe('GEORGE')
                    expect(item.sublist[0].auto_init).toBe('BOB')
                    expect(item.sublist[1].auto).toBe('HARRY')
                    expect(item.sublist[1].auto_init).toBe('BOB')
                    done()
