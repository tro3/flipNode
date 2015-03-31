


getItems = require('./getItems')
createItems = require('./createItems')


module.exports.getListView = (req, res) ->
    # check high-level auth, read & create
    
    getItems(req, {}).then (items) ->
        res.status(200).send(
            _status: 'OK'
            _auth: true
            _items: items
        )
