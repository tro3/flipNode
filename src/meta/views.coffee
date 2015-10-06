p = console.log

types = require('../api').schema.types

[
    [types.Id,        'Id']
    [types.Doc,       'Doc']
    [types.List,      'List']
    [types.String,    'String']
    [types.Integer,   'Integer']
    [types.Float,     'Float']
    [types.Boolean,   'Boolean']
    [types.Date,      'Date']
    [types.Reference, 'Reference']
    [types.Auto,      'Auto']
    [types.AutoInit,  'Auto']
].forEach (x) ->
    x[0].typeName = x[1]



processSchema = (schema) ->
    resp = {}
    for key in Object.keys(schema)
        val = schema[key]
        resp[key] = n = {}
        for attrKey, attr of val
            if attrKey == 'type'
                n.type = attr.typeName
            else if attrKey == 'schema'
                n.schema = processSchema(attr)
            else
                n[attrKey] = attr
    resp
            
    


module.exports.getAll = (req, res, config) ->
    resp = {}
    for key, val of config
        resp[key] = processSchema val.schema
    res.send(resp)
