qForEach = require('./common').qForEach
qForItems = require('./common').qForItems
genTID = require('./common').genTID

p = console.log



deleteItems = (req, data) ->
    endpoint = req.endpoint
    schema = endpoint.schema
    data = [data] if !(data instanceof Array)
    olds = (null for x in data)
    qForEach data, (id, index) ->
        req.cache.findOne(req.collection, {_id:id})
        .then (doc) ->
            olds[index] = doc
    .then ->
        req.cache.remove(req.collection, {_id:{$in:data}})     # Remove items
        .then ->
            hist = []
            data.forEach (id, index) ->                        # Insert histories
                hist.push
                    collection: req.collection
                    item: id
                    action: 'deleted'
                    old: olds[index]
            req.cache.insert 'flipData.history', hist
    .then -> {
        status: 'OK'
        tid: genTID()
    }


module.exports = deleteItems