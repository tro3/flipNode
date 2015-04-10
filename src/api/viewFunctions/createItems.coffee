q = require('q')

types = require('../schema').types
Doc = types.Doc
List = types.List
Reference = types.Reference

qForEach = require('./common').qForEach
qForItems = require('./common').qForItems

incoming = require('./incoming')
merge = require('./merge')
behavior = require('./behavior')
runAuto = require('./auto').runAuto
enforceID = require('./enforceID')


p = console.log



createItems = (req, data, direct=false) ->
    endpoint = req.endpoint
    schema = endpoint.schema
    data = [data] if !(data instanceof Array)
    resp =
        status: 'OK'
        items: (null for x in data)
        errs: (null for x in data)
    qForEach data, (item, index) ->
        itemErrs = []
        if !direct
            itemErrs = itemErrs.concat(incoming(item, schema))              # Enforce existence and clean data
        item = resp.items[index] = merge({}, item, schema)                  # Fill in prototype

        if !direct
            itemErrs = itemErrs.concat(behavior.allowed(item, endpoint))    # Enforce allowed, required, and unique constraints
            itemErrs = itemErrs.concat(behavior.required(item, endpoint))
            tmpQ = behavior.unique(item, endpoint, req).then (result) ->
                itemErrs = itemErrs.concat(result)
        else
            tmpQ = q.Promise.resolve()
        tmpQ.then ->
            resp.status = 'ERR' if itemErrs.length > 0
            resp.errs[index] = itemErrs
    .then ->
        baseID = null
        if resp.status == 'OK'
            delete resp.errs
            req.cache.db.findOne('flipData.ids', {collection:req.collection})
            .then (result) ->
                baseID = result.lastID
                qForEach resp.items, (item, index) ->
                    runAuto(item, endpoint)                               # Run Autos & Defaults
                    enforceID(item, endpoint)                             # Enforce ID's
                    item._id = baseID + index + 1                         # Add top level id        
                    req.cache.insert(req.collection, item)                # Insert item
            .then ->
                hist = []
                resp.items.forEach (item, index) ->                       # Insert history
                    hist.push
                        collection: req.collection
                        item: item._id
                        action: 'created'
                        new: item
                req.cache.insert 'flipData.history', hist
            .then ->
                update =
                    $set:
                        lastID: baseID + data.length
                req.cache.db.update('flipData.ids', {collection:req.collection}, update)
        else
            delete resp.items
    .then ->
        resp
    .catch (err) -> throw err
    
    
module.exports = createItems