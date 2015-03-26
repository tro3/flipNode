schema = require('../schema')
types =  schema.types
List = types.List
Dict = types.Dict
ReadOnly = types.ReadOnly

p = console.log


module.exports = incoming = (data, sch) ->
    for key, val of data
        if key not of sch
            delete data[key]
        else
            newval = sch[key].type(val)
            if newval == types.ReadOnly
                delete data[key]
            else
                data[key] = newval