
module.exports.types =
    List:      require('./types/list')
    Doc:       require('./types/doc')
    Auto:      require('./types/auto')
    AutoInit:  require('./types/autoInit')
    Serialize: require('./types/serialize')

mongoose = require('mongoose')
fnPlugin = require('./plugin')
module.exports.model = (name, schema) ->
    schema.plugin(fnPlugin)
    mongoose.model(name, schema)

module.exports.registerEndpoint = require('./setup')