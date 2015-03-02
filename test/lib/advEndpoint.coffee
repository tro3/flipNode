flipNode = require('../../src')
Schema =   flipNode.Schema
List =     flipNode.types.List
Subdoc =   flipNode.types.Subdoc
Auto =     flipNode.types.Auto
AutoInit = flipNode.types.AutoInit


flipNode.registerEndpoint 'advEndpoint',
    schema:
        name:
            type: String
            required: true
        capname:
            type: Serialize
            exec: (doc) -> doc.name.toUpperCase()
        eid:
            type: Number
            unique: true
        stage:
            type: String
            allowed: (doc) -> if doc.isNew then ['Open'] else ['Pending', 'Closed']
        auto:
            type: Auto
            exec: (doc) -> doc.name.toUpperCase()
        auto_init:
            type: AutoInit
            exec: (doc) -> doc.name.toUpperCase()
        subdoc:
            type: Subdoc
            schema:
                name:
                    type: String
                    default: 'fred'
                auto:
                    type: Auto
                    exec: (doc) -> doc.subdoc.name.toUpperCase()
                auto_init:
                    type: AutoInit
                    exec: (doc, root) -> root.name.toUpperCase()
        sublist:
            type: List
            schema:
                name:
                    type: String
                    default: ''
                auto:
                    type: Auto
                    exec: (doc) -> doc.name.toUpperCase()
                auto_init:
                    type: AutoInit
                    exec: (doc, root) -> root.name.toUpperCase()        
