mg = require('mongoose')
flipNode = require('../../src')

Schema =   flipNode.Schema
Auto =     flipNode.types.Auto
AutoInit = flipNode.types.AutoInit




module.exports = new Schema
    name:
        type: String
        required: true
    eid:
        type: Number
    stage:
        type: String
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

# Add serialize
module.exports.virtual('capname').get ->
    this.name.toUpperCase()


# Add Dynamic Allowed
validateFcn = (doc) ->
    if doc.isNew then ['Open'] else ['Pending', 'Closed']

validateAllowed = (fcn) ->
    (val) ->
        items = fcn(this)
        return items.indexOf(val) != -1
    
module.exports.path('stage').validate validateAllowed validateFcn
    

# Add Unique

validateUnique = (path) ->
    (val, fn) ->
        model = this.model(this.constructor.modelName)
        spec = {}
        spec[path] = val
        model.count spec, (err, cnt) -> fn(err || cnt > 0)


module.exports.path('eid').validate(
    validateUnique('eid'),
    '{VALUE} is not unique'
)
