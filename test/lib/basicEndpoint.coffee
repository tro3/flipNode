
flipNode = require('../../src')
Schema =   flipNode.Schema
List =     flipNode.types.List
Doc =      flipNode.types.Doc


flipNode.registerEndpoint 'basicEndpoint',
    schema:
        name:    String
        number:  Number
        binary:  Buffer
        living:  Boolean
        updated: Date
        mixed:   Schema.Types.Mixed
        _someId: Schema.Types.ObjectId
        ofString:
            type: List
            schema: String
        ofNumber: [Number]
        ofDates:
            type: List
            schema: Date
        ofBuffer:
            type: List
            schema: Buffer
        ofBoolean:
            type: List
            schema: Boolean
        ofMixed:
            type: List
            schema: Schema.Types.Mixed
        ofObjectId:
            type: List
            schema: Schema.Types.ObjectId
        ofDocs:[
            name: String
            age: Number
        ]
        nested:
            type: Doc
            schema:
                data: {type: Number, max: 5}
                tags:
                    type: List
                    schema: {type: String, lowercase: true}
