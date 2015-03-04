
mpath = require('mpath')
    

module.exports = (data) ->
    proto = new Object
    proto.get = (path) -> mpath.get(path, data)
    proto.set = (path, val) -> mpath.set(path, val, data)
    data.__proto__ = proto
    data
    
