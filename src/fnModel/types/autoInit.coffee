debug = require('debug')('AutoInitSchemaType')
mongoose = require('mongoose')
Auto = require('./auto')

class AutoInit extends Auto

    constructor: (key, options) ->
        super key, options
        @_flipData.type = 'auto_init'

mongoose.Schema.Types.AutoInit = AutoInit
mongoose.Types.AutoInit = mongoose.mongo.AutoInit
module.exports = AutoInit
