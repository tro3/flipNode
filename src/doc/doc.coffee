
mpath = require('mpath')
    

module.exports = (data) ->
    proto = new Object
    proto.get = (path) -> if path.trim().length > 0 then mpath.get(path, data) else data
    proto.set = (path, val) -> mpath.set(path, val, data)
    data.__proto__ = proto
    data
    
