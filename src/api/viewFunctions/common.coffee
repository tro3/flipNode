q = require('q')
x = module.exports

x.qForEach = (list, fn) ->
    qs = []
    list.forEach (item, ind, root) -> qs.push fn(item, ind, root)
    q.all(qs)


x.qForItems = (obj, fn) ->
    qs = []
    for key, val of obj
        qs.push fn(key, val)
    q.all(qs)


x.genTID = ->
    Math.random().toString()[2..]