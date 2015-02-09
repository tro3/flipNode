
flipNode = require('../../src')

Schema =   flipNode.Schema
Auto =     flipNode.types.Auto
AutoInit = flipNode.types.AutoInit


module.exports = new Schema
  name: String
  auto:
    type: Auto
    exec: (doc) -> doc.name.toUpperCase()
  auto_init:
    type: AutoInit
    exec: (doc) -> doc.name.toUpperCase()
  subdoc:
    name:
      type: String
      default: ''
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
