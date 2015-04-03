q = require('q')
p = console.log

module.exports = resolveAuth = (attr, auth, req, doc=null, root=null) ->
    val = auth[attr]
    
    if typeof val == 'function'
            if !doc
                return q.Promise.resolve(val(req)).catch -> true
            else if !root
                return q.Promise.resolve(val(doc, req)).catch -> attr != 'create'
            else
                return q.Promise.resolve(val(doc, root, req)).catch -> false
    else
        return q.Promise.resolve(val)
