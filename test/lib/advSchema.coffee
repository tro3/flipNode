
flipNode = require('../../src')

Schema =   flipNode.Schema
Auto =     flipNode.types.Auto
AutoInit = flipNode.types.AutoInit



validateFunction = (doc) ->
  if doc.isNew then ['Open'] else ['Pending', 'Closed']

validateAllowed = (fcn) ->
  (val) ->
    items = fcn(this)
    return items.indexOf(val) != -1
    

module.exports = new Schema
  name:
    type: String
    required: true
  stage:
    type: String
    validate: validateAllowed(validateFunction)
  auto:
    type: Auto
    exec: (doc) -> doc.name.toUpperCase()
  auto_init:
    type: AutoInit
    exec: (doc) -> doc.name.toUpperCase()
  subdoc:
    name:
      type: String
      default: 'fred'
    auto:
      type: Auto
      exec: (doc) -> doc.subdoc.name.toUpperCase()
    auto_init:
      type: AutoInit
      exec: (doc, root) -> root.name.toUpperCase()
  sublist: [
    name:
      type: String
      default: ''
    auto:
      type: Auto
      exec: (doc) -> doc.name.toUpperCase()
    auto_init:
      type: AutoInit
      exec: (doc, root) -> root.name.toUpperCase()    
  ]

module.exports.virtual('capname').get ->
  this.name.toUpperCase()
