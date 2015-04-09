
EventEmitter = require('events').EventEmitter
express = require('express')
bodyParser = require('body-parser')
q = require('q')
DbCache = require('./db').DbCache
Endpoint = require('./schema').Endpoint
viewFcns = require('./viewFunctions')

p = console.log

module.exports.schema = require('./schema')
module.exports.connect = require('./db').connect

maps = {
    'POST': 'create'
    'GET': 'read'
    'PUT': 'edit'
    'DELETE': 'delete'
}




module.exports.api = (db, config) ->
    router = express.Router()
    router.events = new EventEmitter()
    router.config = config
    
    router.use(bodyParser.json())
    router.use (err,req,res,next) ->
        next if !err
        res.status(400).send viewFcns.MALFORMED
    
    for key, val of config
        config[key] = new Endpoint(val)

    handle = (fn, req, res) ->
        res.handled = true
        req.endpoint = config[req.collection]
        req.cache = new DbCache(db)
        router.events.emit "pre", req, res
        router.events.emit "#{maps[req.method]}.pre", req, res
        router.events.emit "#{req.collection}.#{maps[req.method]}.pre", req, res
        fn(req, res)
        .then ->
            if res.statusCode == 200
                router.events.emit "post", req, res
                router.events.emit "#{maps[req.method]}.post", req, res
                router.events.emit "#{req.collection}.#{maps[req.method]}.post", req, res
                if res.body
                    res.send(res.body)
                else
                    res.status(204).send()
        .catch -> null
        .done null, (err) -> throw err


    router.param 'collection', (req, res, next) ->
        req.collection = req.params.collection
        if 'id' of req.params
            req.id = parseInt(req.params.id) 
        if !(req.collection of config)
            res.status(404).send()
            return
        next()
        
    router.use                              (req, res, next) -> res.handled = false; next()
    router.get '/:collection',              (req, res, next) -> handle(viewFcns.getListView,    req, res)
    router.get '/:collection/:id(\\d+)',    (req, res, next) -> handle(viewFcns.getItemView,    req, res)
    router.post '/:collection',             (req, res, next) -> handle(viewFcns.createItemView, req, res)
    router.put '/:collection/:id(\\d+)',    (req, res, next) -> handle(viewFcns.updateItemView, req, res)
    router.delete '/:collection/:id(\\d+)', (req, res, next) -> handle(viewFcns.deleteItemView, req, res)

    router.use (req, res) ->
        if !res.handled
            res.status(404).send()
            
    router


module.exports.prepDB = (db, config) ->
    return q.Promise.resolve() if !db
    db.find('flipData.ids').then (docs) ->
        colls = (x.collection for x in docs)
        for key of config
            if !(key in colls)            
                db.insert('flipData.ids', {collection:key, lastID:0})
