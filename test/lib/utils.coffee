
mpath = require('mpath')
execValTree = require('../../src/utils').execValTree

module.exports.equivObject = (dut, exp) ->
    result = typeof dut == 'object'
    execValTree exp, (val, path) ->
        result = result && mpath.get(path, dut) == val
    result