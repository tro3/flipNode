
module.exports.types =
    List:     require('./types/list')
    Subdoc:   require('./types/subdoc')
    Auto:     require('./types/auto')
    AutoInit: require('./types/autoInit')

mongoose = require('mongoose')
fnPlugin = require('./plugin')
module.exports.model = (name, schema) ->
    schema.plugin(fnPlugin)
    mongoose.model(name, schema)

module.exports.registerEndpoint = require('./setup')