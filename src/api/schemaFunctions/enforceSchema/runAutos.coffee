mpath = require('mpath')
schema = require('../schema')
types =  schema.types
Auto = types.Auto
AutoInit = types.AutoInit

p = console.log
x = module.exports


parentPath = (path) -> path.split('.')[...-1].join('.')
lastPath = (path) -> path.split('.')[-1..-1]


# Get parents of all paths
# Set parent[attr] = function

x.runAuto = (data, endpoint, req) ->
    for path, sch of endpoint.paths.autos
        list = mpath.get(parentPath(path), data) || data
        if !(list instanceof Array)
            list = [list]
        for element in list
            element[lastPath(path)] = sch.auto(element, data, req)

    for path, sch of endpoint.paths.autoInits
        list = mpath.get(parentPath(path), data) || data
        if !(list instanceof Array)
            list = [list]
        for element in list
            if !element._id
                element[lastPath(path)] = sch.auto(element, data, req)

    for path, sch of endpoint.paths.defaults
        list = mpath.get(parentPath(path), data) || data
        if !(list instanceof Array)
            list = [list]
        for element in list
            key = lastPath(path)
            if element[key] == null || element[key] == undefined
                element[key] = sch.default
