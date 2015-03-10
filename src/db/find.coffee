q = require("q")
p = console.log

Auth = require('../auth')


qFind = (db, collName, query, options) ->
    q.Promise (resolve, reject) ->
        db.collection(collName).find(query, options).toArray (err, docs) ->
            reject err if err
            resolve docs



serializeAuth = (doc, authState, top=false) ->
    doc._auth =
        _edit: authState.edit    
    if top
        doc._auth._delete = authState.delete
    if authState.children
        for key, val of authState.children
            if val.children instanceof Array
                doc._auth[key] = val.create
                doc[key].forEach (subdoc, ind) -> serializeAuth(subdoc, val.children[ind], true) 
            else
                serializeAuth(doc[key], val)


enforceReadAuth = (doc, authState) ->
    if authState.children
        for key, val of authState.children
            if !val.read
                delete doc[key]
            else if val.children and val.children instanceof Array
                
            else if val.children
                if !val.read
                    delete doc[key]

module.exports = find = (db, collName, endpoint, query={}, options={}, user) ->
    docs = []
    fields = options.fields || null
    delete options.fields

    
    # Get Full Objects
    
    qFind(db, collName, query, options)
    .then (results) ->
        results.forEach (x) -> docs.push {doc:x}
        
        # Check high level auth
        
        
        # Get Projections
        
        options.fields = fields if fields
        ids = (x._id for x in results)
        qFind(db, collName, {_id: {$in: ids}}, options)

    .then (results) ->
        results.forEach (x) -> docs.filter((y) -> y.doc._id.equals(x._id))[0].projection = x
        
        # Get Auth
        docs.forEach (doc) -> doc.auth = new Auth(endpoint, doc.doc, user, db)

        # Enforce Auth
        
        # Expand References
        
        # Add serial _auth
        docs.forEach (doc) -> serializeAuth(doc.projection, doc.auth, true)
        
        
        docs
        

