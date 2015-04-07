p = console.log

x = module.exports

x.ReadOnly = () ->
    
x.List = () -> x.TypeError # Should never be used
x.Doc = () -> x.TypeError # Should never be used

x.Auto = (val) -> x.ReadOnly
x.AutoInit = (val) -> x.ReadOnly


x.String = (val) -> String(val)

x.Integer = (val) ->
    val = parseInt(val)
    if isNaN(val)
        throw new Error 
    val

x.Float = (val) ->
    val = parseFloat(val)
    if isNaN(val)
        throw new Error 
    val

x.Reference = (val) ->
    if !('_id' of val)
        throw new Error
    id = parseInt(val._id)
    if isNaN(id)
        throw new Error
    id
    
x.Date = (val) ->
    val = new Date(val)
    if val.toString() == 'Invalid Date'
        throw new Error 
    val
    
x.Boolean = (val) -> Boolean(val)
