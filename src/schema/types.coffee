
x = module.exports

x.ReadOnly = () ->
x.TypeError = () ->
    
x.List = () -> x.TypeError # Should never be used
x.Dict = () -> x.TypeError # Should never be used

x.Auto = (val) -> x.ReadOnly
x.AutoInit = (val) -> x.ReadOnly


x.String = (val) -> String(val)

x.Integer = (val) -> parseInt(val)

x.Float = (val) -> parseFloat(val)

x.Reference = (val) -> parseInt(val._id)
    
x.Date = (val) -> new Date(val)
    
x.Boolean = (val) -> Boolean(val)
