q = require('q')

types = require('../schema').types
Dict = types.Dict
List = types.List

p = console.log


qForEach = (list, fn) ->
    qs = []
    list.forEach (item, ind, root) -> qs.push fn(item, ind, root)
    q.all(qs)


qForItems = (obj, fn) ->
    qs = []
    for key, val of obj
        qs.push fn(key, val)
    q.all(qs)




getItems = (req, query={}, options={}) ->
    collName = req.collection
    items = null
    ids = null

    
    # Get Full Docs
    fields = options.fields
    delete options.fields

    req.cache.find(collName, query, options)
    .then (results) ->
        items = results
        ids = (x._id for x in items)

            
    # Check read auth for each item
        auths = (undefined for x in items)
        qForEach results, (doc, ind) ->
            auths[ind] = true
            q.Promise.resolve()
            
        ids.filter (x, ind) -> auths[ind]


    # Get remaining doc projections
    options.fields = fields 
    req.cache.find(collName, query, options)


    # Enforce auth and serialize
    .then (results) ->
        req.active = results
        qForEach results, (doc) ->
            serializeAuth(req, doc)
            .then -> expandRefs(req, doc)
    .then ->
        return req.active




perms = ['create', 'edit', 'delete']

serializeAuth = (req, doc) ->
    fullDoc = req.cache.findOne(req.collection, {_id:doc._id})
    .then (fullDoc) ->
        _serializeAuthRec(req, doc, fullDoc, req.endpoint)

_serializeAuthRec = (req, doc, fullDoc, endp, subdoc, prev, root) ->
    debugger
    schema = endp.schema
    auth = endp.auth || {}
    subdoc = subdoc || false
    prev = prev || {}
    root = root || fullDoc
    type = endp.type || Dict
    
    resolve = (val, full, attr) ->
        if typeof val == 'function'
            if attr == 'create'
                return q.Promise.resolve(val(root, req))
            else
                return q.Promise.resolve(val(full, root, req))
        else
            return q.Promise.resolve(val)

    evaluate = (attr, full, authObj=auth) ->
        if attr of authObj
            resolve(authObj[attr], full, attr)
        else if attr of prev
            q.Promise.resolve(prev[attr])
        else
            q.Promise.resolve(true)
        
    evaluate('read', fullDoc)
    .then (readAuth) ->
        return false if !readAuth
                
        state = {}
        qForEach perms, (perm) ->
            evaluate(perm, fullDoc)
            .then (result) -> state[perm] = result

        .then ->
            if type == Dict

                doc._auth = {_edit: state.edit}
                if !subdoc
                    doc._auth._delete = state.delete

                qForItems schema, (key, val) ->
                    if 'schema' of val and key of doc
                        if val.type == Dict
                            full = if (key of fullDoc) then fullDoc[key] else {}
                            _serializeAuthRec(req, doc[key], full, val, true, state, root)
                            .then (authed) -> delete doc[key] if !authed
                        else if val.type == List
                            full = if (key of fullDoc) then fullDoc[key] else []
                            evaluate('create', full, if 'auth' of val then val.auth else {})
                            .then (result) ->
                                doc._auth[key] = result                            
                                _serializeAuthRec(req, doc[key], full, val, true, state, root)
                                .then (authed) -> delete doc[key] if !authed
                        else
                            throw new Error('Malformed schema, "schema" prop for non-Dict/List')

            else if type == List
                auths = []
                localEndp =
                    type: Dict
                    auth: auth
                    schema: schema
                qForEach doc, (subdoc, ind) ->
                    full = fullDoc[ind]
                    _serializeAuthRec(req, subdoc, full, localEndp, false, state, root)
                    .then (authed) -> auths.push(index) if !authed
                .then ->
                    auths.sort()
                    auths.reverse()
                    for ind in auths
                        delete doc[ind]

            else
                throw new Error('Malformed document, needs to be Dict or List')
                    
        .then -> true
                    


expandRefs = (req, doc) ->
    q.Promise.resolve()
        
            
    
    
    
    
x = module.exports
x.getItems = getItems