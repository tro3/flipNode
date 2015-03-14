
getItems = require('./getItems')

x = module.exports


x.getList(req, res) =
    # Check high-level auth
    
    query = # extract from URL query
    options = # extract from URL query
        
    getItems(req, query, options)
    .then ->
        resp =
            _status: 'OK'
            _auth: req.endpoint.auth.create
            _items: req.active
    .catch (err) ->
        resp =
            _status: 'ERR'
    .finally ->
        JSON.stringify resp


x.getOne(req, res) =
    # Check high-level auth
    
    query = {_id: urlID} # extract from URL
    options = {}
        
    getItems(req, query, options)
    .then ->
        resp =
            _status: 'OK'
            _auth: req.endpoint.auth.create
            _item: req.active[0]
    .catch (err) ->
        resp =
            _status: 'ERR'
    .finally ->
        JSON.stringify resp
