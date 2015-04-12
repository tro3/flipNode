
Primus = require('primus')


module.exports = (server, api, config) ->
    filename = (config && config.filename) || './primus.js'

    primus = new Primus(server, {transformer: 'SockJS'})
    primus.save(filename)
     
    primus.on 'connection', (spark) ->  

      api.events.on 'create.post', (req, res) ->
        spark.write (
            action: 'create'
            collection: req.collection
            id: res.body._item._id
        )

      api.events.on 'edit.post', (req, res) ->
        spark.write (
            action: 'edit'
            collection: req.collection
            id: req.id
        )

      api.events.on 'delete.post', (req, res) ->
        spark.write (
            action: 'delete'
            collection: req.collection
            id: req._id
        )
