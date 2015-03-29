q = require('q')

types = require('../schema').types
Dict = types.Dict
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
            tmp = incoming(item, schema)
            itemErrs = itemErrs.concat(tmp)                                 # Enforce existence and clean data
        item = merge({}, item, schema)                                      # Fill in prototype
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
            req.cache.db.findOne('flipData', {_id:'ids'})
            .then (ids) ->
                baseID = ids[req.collection]
                qForEach data, (item, index) ->
                    runAuto(item, endpoint)                               # Run Autos
                    enforceID(item, endpoint)                             # Enforce ID's
                    item._id = baseID + index + 1                         # Add top level id        
                    resp.items[index] = item
                    req.cache.insert(req.collection, item)                # Insert item
            .then ->
                1                                                         # Insert history
            .then ->
                update =
                    $set: {}
                update.$set[req.collection] = baseID + data.length
                req.cache.db.update('flipData', {_id:'ids'}, update)
        else
            delete resp.items
    .then ->
        resp
                
            
            
        

#enforce auth on incoming*
    #existence
    #readonly
#enforce datatypes on incoming*
#merge incoming (with {}) & fill in protos
#enforce schema behaviors*
    #allowed
    #required
    #unique
#run Auto / AutoInit funcs
#enforce ids
#insert item
#add history    



    
    
module.exports = createItems