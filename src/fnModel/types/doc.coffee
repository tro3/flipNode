mongoose = require('mongoose')

class Doc extends mongoose.SchemaType

mongoose.Schema.Types.Doc = Doc
mongoose.Types.Doc = mongoose.mongo.Doc
module.exports = Doc
