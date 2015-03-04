
mpath = require('mpath')
execValTree = require('../../src/utils').execValTree

module.exports.equivObject = (dut, exp) ->
    result = true
    execValTree exp, (val, path) ->
        result = result && mpath.get(path, dut) == val
    return result