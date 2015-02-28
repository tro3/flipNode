debug = require('debug')('AutoSchemaType')
mongoose = require('mongoose')
SchemaString = mongoose.Schema.Types.String

class Auto extends mongoose.SchemaType

    constructor: (key, options) ->
        super key, options
        @_flipType = 'auto'
        @_exec = options.exec
        @_resultType = options.resultType || new SchemaString()
        
    checkRequired: (val) -> @_resultType.checkRequired(val)
    cast: (val) -> @_resultType.cast(val)
    castForQuery: ($conditional, value) -> @_resultType.castForQuery($conditional, value)


mongoose.Schema.Types.Auto = Auto
mongoose.Types.Auto = mongoose.mongo.Auto
module.exports = Auto
