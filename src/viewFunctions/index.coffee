q = require('q')
getItems = require('./getItems')
createItems = require('./createItems')
p = console.log

resolve = (attr, args...) ->
    attr = if (attr != undefined && attr != null) then attr else true
    if typeof attr == 'function'
        return q.Promise.resolve(attr.apply(@, args)).catch ->
            p 'err'
            q.Promise.resolve true
    else
        return q.Promise.resolve attr


module.exports.getListView = (req, res) ->
    # check high-level auth, read & create

    if typeof req.endpoint.auth.read == 'boolean' && !req.endpoint.auth.read
        res.status(403).send()
        q.Promise.resolve true
    else
        resolve(req.endpoint.auth.create, req)
        .then (createAuth) ->
            getItems(req, {}).then (items) ->
                res.status(200).send(
                    _status: 'OK'
                    _auth: createAuth
                    _items: items
                )
        .catch (err) -> throw err
