mongoose = require('mongoose')
fnPlugin = require('./plugin')


module.exports.types =
    Auto: require('./types/auto')

module.exports.model = (name, schema) ->
    schema.plugin(fnPlugin)
    mongoose.model(name, schema)
