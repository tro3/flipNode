q = require('q')
evalAuth = require('./auth')
getItems = require('./getItems')
createItems = require('./createItems')
updateItems = require('./updateItems')
deleteItems = require('./deleteItems')

p = console.log


NOT_FOUND =
    _status: 'ERR'
    _msg: 'Not found'
    
MALFORMED =
    _status: 'ERR'
    _msg: 'Malformed data'

UNAUTHORIZED =
    _status: 'ERR'
    _msg: 'Unauthorzied'
    


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
        res.status(403).send(UNAUTHORIZED)
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
        res.status(403).send(UNAUTHORIZED)
        q.Promise.resolve true
    else
        options = {}
        if 'fields' of req.query
            options.fields = JSON.parse(req.query.fields)
        getItems(req, {_id:parseInt(req.params.id)}, options, true).then (items) ->
            if items == false
                res.status(403).send(UNAUTHORIZED)
            else if items.length > 0
                res.status(200).send(
                    _status: 'OK'
                    _item: items[0]
                )
            else
                res.status(404).send(NOT_FOUND)
        .catch (err) -> throw err


module.exports.createItemView = (req, res) ->
    item = null
    id = null
    
    # Check high-level auth
    evalAuth('create', req.endpoint.auth, req)
    .then (auth) ->
        if !auth
            res.status(403).send(UNAUTHORIZED)
            return
        if not 'body' of req
            res.status(400).send(MALFORMED)
            return

        item = req.body
                    
        # Create item
        createItems(req, [item]).then (resp) ->
            if resp.status == 'OK'
                getItems(req, {_id:resp.items[0]._id}, {}, true).then (items) ->
                    res.status(200).send(
                        _status: 'OK'
                        _item: items[0]
                    )
            else
                res.status(200).send(
                    _status: 'ERR'
                    _errs: resp.errs[0]
                )
            
    .catch (err) -> throw err


module.exports.updateItemView = (req, res) ->
    item = null
    id = null
    
    # Check high-level auth
    evalAuth('edit', req.endpoint.auth, req)
    .then (auth) ->
        if !auth
            res.status(403).send(UNAUTHORIZED)
            return
        if not 'body' of req
            res.status(400).send(MALFORMED)
            return

        item = req.body
        id = parseInt(req.params.id)
        getItems(req, {_id:id}, {}, true).then (dbItems) ->
            if dbItems.length == 0
                res.status(404).send(NOT_FOUND)
                return
            if item._id != parseInt(req.params.id)
                res.status(400).send(MALFORMED)
                return
            evalAuth('edit', req.endpoint.auth, req, dbItems[0])

    .then (auth) ->
        if !auth
            res.status(403).send(UNAUTHORIZED)
            return
                    
        # Update items
        updateItems(req, [item]).then (resp) ->
            if resp.status == 'OK'
                if resp.items.length > 0
                    getItems(req, {_id:id}, {}, true).then (items) ->
                        res.status(200).send(
                            _status: 'OK'
                            _item: items[0]
                        )
                else
                    res.status(403).send(UNAUTHORIZED)
            else
                res.status(200).send(
                    _status: 'ERR'
                    _errs: resp.errs[0]
                )
            
    .catch (err) -> throw err


module.exports.deleteItemView = (req, res) ->
    item = null
    id = null
    
    # Check high-level auth
    evalAuth('delete', req.endpoint.auth, req)
    .then (auth) ->
        if !auth
            res.status(403).send(UNAUTHORIZED)
            return

        id = parseInt(req.params.id)
        getItems(req, {_id:id}, {}, true).then (dbItems) ->
            if dbItems.length == 0
                res.status(404).send(NOT_FOUND)
                return
            evalAuth('delete', req.endpoint.auth, req, dbItems[0])

    .then (auth) ->
        if !auth
            res.status(403).send(UNAUTHORIZED)
            return

        # Delete items
        deleteItems(req, [id]).then (resp) ->
            if resp.status == 'OK'
                res.status(200).send(
                    _status: 'OK'
                )
            else
                res.status(200).send(
                    _status: 'ERR'
                    _errs: resp.errs[0]
                )
            
    .catch (err) -> throw err
