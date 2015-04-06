
flipNode = require('../../src/api')
Schema =   flipNode.Schema


module.exports = new Schema
  name:    String
  number:  Number
  binary:  Buffer
  living:  Boolean
  updated: Date
  mixed:   Schema.Types.Mixed
  _someId: Schema.Types.ObjectId
  array:      []
  ofString:   [String]
  ofNumber:   [Number]
  ofDates:    [Date]
  ofBuffer:   [Buffer]
  ofBoolean:  [Boolean]
  ofMixed:    [Schema.Types.Mixed]
  ofObjectId: [Schema.Types.ObjectId]
  nested: 
    stuff: {type: String, lowercase: true, trim: true}
