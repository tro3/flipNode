
express = require('express')
DbCache = require('./db').DbCache
Endpoint = require('./schema').Endpoint
viewFcns = require('./viewFunctions')

module.exports.schema = require('./schema')

module.exports.api = (db, config) ->
    router = express.Router()
    
    for key, val of config
        config[key] = new Endpoint(val)

    router.param 'collection', (req, res, next) ->
        req.collection = req.params.collection
        if !(req.collection of config)
            res.status(404).send()
            return
        req.endpoint = config[req.collection]
        req.cache = new DbCache(db)
        next()

    router.get '/:collection', (req, res) -> viewFcns.getListView(req, res)
    router.get '/:collection/:id(\\d+)', (req, res) -> viewFcns.getItemView(req, res)
    
    router
