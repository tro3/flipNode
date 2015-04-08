
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


    router.param 'collection', (req, res, next) ->
        req.collection = req.params.collection
        if 'id' of req.params
            req.id = parseInt(req.params.id) 
        if !(req.collection of config)
            res.status(404).send()
            return
        req.endpoint = config[req.collection]
        req.cache = new DbCache(db)

        # We can put these here because all api url include a collection param
        router.events.emit "pre", req, res
        router.events.emit "#{maps[req.method]}.pre", req, res
        router.events.emit "#{req.collection}.#{maps[req.method]}.pre", req, res
        next()
        
    router.get '/:collection', (req, res, next) -> viewFcns.getListView(req, res).then -> next()
    router.get '/:collection/:id(\\d+)', (req, res, next) -> viewFcns.getItemView(req, res).then -> next()
    router.post '/:collection', (req, res, next) -> viewFcns.createItemView(req, res).then -> next()
    router.put '/:collection/:id(\\d+)', (req, res, next) -> viewFcns.updateItemView(req, res).then -> next()
    router.delete '/:collection/:id(\\d+)', (req, res, next) -> viewFcns.deleteItemView(req, res).then -> next()

    router.use (req, res) ->
        if res.statusCode == 200
            router.events.emit "post", req, res
            router.events.emit "#{maps[req.method]}.post", req, res
            router.events.emit "#{req.collection}.#{maps[req.method]}.post", req, res
            if res.body
                res.send(res.body)
            else
                res.status(204)
    
    router


module.exports.prepDB = (db, config) ->
    return q.Promise.resolve() if !db
    db.find('flipData.ids').then (docs) ->
        colls = (x.collection for x in docs)
        for key of config
            if !(key in colls)            
                db.insert('flipData.ids', {collection:key, lastID:0})
