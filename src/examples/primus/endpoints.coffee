
flip = require('../..')
types = flip.schema.types

List = types.List
Doc = types.Doc
Auto = types.Auto
AutoInit = types.AutoInit
String = types.String
Integer = types.Integer
Float = types.Float
Reference = types.Reference
Date = types.Date
Boolean = types.Boolean
ReqString = {type: String, required: true}

module.exports =
    users:
        username: ReqString
        firstName: String
        lastName: String
        fullName: {type: Auto, auto: (el) -> "#{el.firstName} #{el.lastName}"}
            
    toDos:
        description: ReqString
        assignee:
            type: Reference
            collection: 'users'
            fields: ['fullName']
        complete: {type: Boolean, default: false}