mongoose = require('mongoose')

class Subdoc extends mongoose.SchemaType

mongoose.Schema.Types.Subdoc = Subdoc
mongoose.Types.Subdoc = mongoose.mongo.Subdoc
module.exports = Subdoc
