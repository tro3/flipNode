q = require('q')
mpath = require('mpath')

types = require('../schema').types
Doc = types.Doc
List = types.List
Reference = types.Reference

evalAuth = require('./auth')
qForEach = require('./common').qForEach
qForItems = require('./common').qForItems

p = console.log



getItems = (req, query={}, options={}, single=false) ->
    collName = req.collection
    items = null
    ids = null
    auths = null
    
    fields = options.fields                                             # Get Full Docs
    delete options.fields

    req.cache.find(collName, query, options)
    .then (results) ->
        items = results
        ids = (x._id for x in items)
            
        auths = (undefined for x in items)                              # Check read auth for each item
        qForEach results, (doc, ind) ->
            evalAuth 'read', req.endpoint.auth, req, doc
            .then (auth) -> auths[ind] = auth
            
    .then ->                                                            # Get remaining doc projections
        ids = ids.filter (x, ind) -> auths[ind]
        query = if single then {_id: ids[0]} else {_id: {$in:ids}}
        options.fields = fields
        delete options.limit
        delete options.skip
        req.cache.find(collName, query, options)

    .then (results) ->                                                  # Enforce auth and serialize
        req.active = results
        qForEach results, (doc) ->
            serializeAuth(req, doc)
            .then -> expandRefs(req, doc)
    .then ->
        if single && auths[0] == false
            return false
        else
            return req.active
    .catch (err) -> throw err





perms = ['create', 'edit', 'delete']

serializeAuth = (req, doc) ->
    fullDoc = req.cache.findOne(req.collection, {_id:doc._id})
    .then (fullDoc) ->
        _serializeAuthRec(req, doc, fullDoc, req.endpoint)

_serializeAuthRec = (req, doc, fullDoc, endp, subdoc, prev, root) ->
    schema = endp.schema
    auth = endp.auth || {}
    subdoc = subdoc || false
    prev = prev || {}
    root = root || fullDoc
    type = endp.type || Doc
    
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
            if type == Doc

                doc._auth = {_edit: state.edit}
                if !subdoc
                    doc._auth._delete = state.delete

                qForItems schema, (key, val) ->
                    if 'schema' of val and key of doc
                        if val.type == Doc
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
                            throw new Error('Malformed schema, "schema" prop for non-Doc/List')

            else if type == List
                auths = []
                localEndp =
                    type: Doc
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
                throw new Error('Malformed document, needs to be Doc or List')
                    
        .then -> true
                    


#from .get(path):
#    id
#    [id1, id2]
#    [[id1, id2], [id3]]

expandRefs = (req, doc) ->
    refs = req.endpoint.paths.references || {}
    qForItems refs, (path, config) ->
        if 'subtype' of config
            config = config.subtype
        ids = mpath.get(path, doc)
        return q.Promise.resolve() if !ids
        
        lvl = 0
        if !(ids instanceof Array)
            lvl += 1
            ids = [ids]
        if !(ids[0] instanceof Array)
            lvl += 1
            ids = [ids]
                
        newrefs = ((null for y in x) for x in ids)
        qForEach(ids, (row, i) ->
            qForEach row, (id, j) ->
                _expandSingle(req, config, id)
                .then (ref) ->
                    newrefs[i][j] = ref
        ).then ->
            while lvl
                newrefs = newrefs[0]
                lvl -= 1
            mpath.set(path, newrefs, doc)
        
    
_expandSingle = (req, config, id) ->
    req.cache.findOne(config.collection, {_id:id})
    .then (ref) ->
        sref = {_id: id}
        for fld in config.fields
            sref[fld] = if ref then ref[fld] else 'broken reference'
        sref
    
    
module.exports = getItems