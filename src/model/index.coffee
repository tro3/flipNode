mongoose = require('mongoose')


execTree = (schema, doc, root, fcn) ->
    for path, type of schema.paths
        if type.schema
            for item in doc.get(path)
                execTree(type.schema, item, root, fcn)
        else
            fcn(type, path, doc, root)
    

flipPlugin = (schema, options) ->
    schema.add({ lastMod: Date })
    
    # Handle auto functions
    schema.pre 'save', (next) ->
        doc = @
        execTree schema, doc, doc, (type, path, doc, root) ->
            if type._flipType == 'auto'
                doc.set(path, type._exec(doc, root))
            else if type._flipType == 'auto_init' and doc.isNew
                doc.set(path, type._exec(doc, root))
        next()



module.exports.types =
    Auto: require('./types/auto')
    AutoInit: require('./types/autoInit')

module.exports.Schema = mongoose.Schema
module.exports.connect = (conn) -> mongoose.connect(conn)
module.exports.disconnect = () -> mongoose.disconnect()

module.exports.model = (name, schema) ->
    schema.plugin(flipPlugin)
    mongoose.model(name, schema)
