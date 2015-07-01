assert = require('chai').assert
x = module.exports

x.assertBody = (data, exp) ->
    assert.property data, '_tid'
    assert.typeOf data._tid, 'number'
    tmp = data._tid
    delete data._tid
    assert.deepEqual data, exp
    data._tid = tmp