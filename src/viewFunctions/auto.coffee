schema = require('../schema')
types =  schema.types
Auto = types.Auto
AutoInit = types.AutoInit

p = console.log
x = module.exports


parentPath = (path) -> path.split('.')[...-1].join('.')
lastPath = (path) -> path.split('.')[-1..-1]


x.runAuto = (data, endpoint, req) ->
    for path, sch of endpoint.paths.autos
        list = data.get(parentPath(path))
        if !(list instanceof Array)
            list = [list]
        for element in list
            element[lastPath(path)] = sch.auto(element, data, req)

    for path, sch of endpoint.paths.autoInits
        list = data.get(parentPath(path))
        if !(list instanceof Array)
            list = [list]
        for element in list
            if !element._id
                element[lastPath(path)] = sch.auto(element, data, req)
