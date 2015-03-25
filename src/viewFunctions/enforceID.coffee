mpath = require('mpath')
p = console.log

module.exports = enforceID = (data, endp) ->
    for path, sch of endp.paths.docs
        docs = data.set(path+'._id', 1)       

    for path, sch of endp.paths.lists
        newlists = mpath.get path, data, (list) ->
            ids = (x._id || 0 for x in list)
            last = Math.max.apply(null, ids)
            for item in list
                if !item._id
                    last += 1
                    item._id = last
