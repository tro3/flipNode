

mongoose = require('mongoose')
fnModel = require('./fnModel')

module.exports.Schema = mongoose.Schema
module.exports.types = fnModel.types
module.exports.registerEndpoint = fnModel.registerEndpoint