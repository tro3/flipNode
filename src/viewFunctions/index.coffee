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
            query = {}
            options = {}
            page = null
            size = null
            if 'query' of req.query
                query = JSON.parse(req.query.query)
            if 'fields' of req.query
                options.fields = JSON.parse(req.query.fields)
            if 'sort' of req.query
                options.sort = JSON.parse(req.query.sort)
            if 'page' of req.query
                size = (req.query.pageSize && parseInt(req.query.pageSize)) || 50
                page = parseInt(req.query.page)
                options.skip = (page-1)*size
                options.limit = size
            getItems(req, query, options).then (items) ->
                resp = 
                    _status: 'OK'
                    _auth: createAuth
                    _items: items
                if 'page' of req.query
                    delete options.skip
                    delete options.limit
                    req.cache.count(req.collection, query, options)
                    .then (count) ->
                        resp._page = page
                        resp._pages = Math.ceil(count/size)
                        res.status(200).send(resp)
                else
                    res.status(200).send(resp)
        .catch (err) -> throw err


module.exports.getItemView = (req, res) ->
    # check high-level auth
    if typeof req.endpoint.auth.read == 'boolean' && !req.endpoint.auth.read
        res.status(403).send()
        q.Promise.resolve true
    else
        options = {}
        if 'fields' of req.query
            options.fields = JSON.parse(req.query.fields)
        getItems(req, {_id:parseInt(req.params.id)}, options, true).then (items) ->
            if items == false
                res.status(403).send()
            else if items.length > 0
                res.status(200).send(
                    _status: 'OK'
                    _item: items[0]
                )
            else
                res.status(404).send()
        .catch (err) -> throw err
