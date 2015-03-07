
# Auths part of schema, can only exist on same level as schema, and applied to that schema
# Simple lists are subject to the auth at their level
#
# attr1:
#   type: Dict
#   auth:
#     read: true
#     edit: false
#   schema:
#     subattr1: ...
# attr2:
#   type: List
#   auth:
#     create: false
#     read: true
#     delete: false
#   schema:
#     subattr1: ...
#

# This assumes high-level auth has alreay been checked, endpoint.schema is expanded, and full doc is present
# user and db are only presented for auth functions

types = require('../schema').types
Dict = types.Dict
List = types.List
p = console.log

perms = ['create', 'read', 'edit', 'delete']

_genAuth = (result, endpoint, doc, user, db, prev, root) ->
    
    auth = endpoint.auth || {}
    schema = endpoint.schema
    doc = doc || {}
    prev = prev || {}
    root = root || doc
    
    resolve = (val) ->
        if typeof val == 'function'
            return val(doc, root, user, db)
        else
            return val    

    for attr in perms
        if attr of auth
            result[attr] = resolve(auth[attr])
        else if attr of prev
            result[attr] = prev[attr]
        else
            result[attr] = true

    state = {}
    for attr in perms
        state[attr] = result[attr]

    for key, val of schema
        if 'schema' of val
            result.children = {} if !('children' of result)
            if val.type == Dict
                subdoc = if (key of doc) then doc[key] else {}
                result.children[key] = _genAuth({}, val, subdoc, user, db, state, root)
            else if val.type == List
                result.children[key] = []
                for subdoc in doc[key]
                    result.children[key].push(_genAuth({}, val, subdoc, user, db, state, root))               
            else
                throw new Error('Malformed schema, "schema" prop for non-Dict/List')
    result


class Auth
    constructor: (endpoint, doc, user, db) ->
        _genAuth(@, endpoint, doc, user, db)
        
    get: (path) ->
        current = @
        if path
            parts = path.split('.')        
            for part in parts
                if current instanceof Array
                    ind = parseInt(part)
                    current = current[ind]
                else                
                    if 'children' not of current or part not of current.children
                        throw new Error('Nonexistent Auth path')
                    current = current.children[part]
            
        return {
            create: current.create
            read:   current.read
            edit:   current.edit
            delete: current.delete
        }


module.exports = Auth
