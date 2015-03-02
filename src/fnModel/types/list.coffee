mongoose = require('mongoose')

class List extends mongoose.SchemaType

mongoose.Schema.Types.List = List
mongoose.Types.List = mongoose.mongo.List
module.exports = List
