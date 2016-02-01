q = require('q')

types = require('../schema').types
Doc = types.Doc
List = types.List
Reference = types.Reference

qForEach = require('./common').qForEach
qForItems = require('./common').qForItems
genTID = require('./common').genTID

incoming = require('./incoming')
merge = require('./merge')
behavior = require('./behavior')
runAuto = require('./auto').runAuto
enforceID = require('./enforceID')
diff = require('./diff')


p = console.log



updateItems = (req, data, direct=false) ->
    endpoint = req.endpoint
    schema = endpoint.schema
    data = [data] if !(data instanceof Array)
    olds = (null for x in data)
    resp =
        status: 'OK'
        items: (null for x in data)
        errs: (null for x in data)
    qForEach data, (item, index) ->
        itemErrs = []
        req.cache.findOne(req.collection, {_id:item._id})
        .then (doc) ->
            olds[index] = doc
            data[index] = item = merge(doc, item, schema)                        # Merge and fill in prototype
            if !direct
                itemErrs = itemErrs.concat(incoming(item, schema))               # Enforce existence and clean data
                itemErrs = itemErrs.concat(behavior.allowed(item, endpoint))     # Enforce allowed, required, and unique constraints
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
            resp.tid = genTID()
            qForEach data, (item, index) ->
                runAuto(item, endpoint)                                        # Run Autos & Defaults
                enforceID(item, endpoint)                                      # Enforce ID's
                resp.items[index] = item
                req.cache.update(req.collection, {_id:item._id}, item)         # Insert item
            .then ->
                hist = []
                data.forEach (item, index) ->                                  # Insert history
                    diff(olds[index], item).forEach (histItem) ->
                        histItem.collection = req.collection
                        histItem.item = item._id
                        hist.push histItem
                req.cache.insert 'flipData.history', hist
        else
            delete resp.items
    .then ->
        resp

    
module.exports = updateItems