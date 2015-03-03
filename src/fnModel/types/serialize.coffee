mongoose = require('mongoose')

class Serialize extends mongoose.SchemaType

mongoose.Schema.Types.Serialize = Serialize
mongoose.Types.Serialize = mongoose.mongo.Serialize
module.exports = Serialize
