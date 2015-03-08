
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
# At List level, create refers to List, remainders are applied to children.
# Create functions do not receive element as the first argument

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
    type = endpoint.type || Dict
    
    resolve = (val, el, attr) ->
        if typeof val == 'function'
            if attr == 'create'
                return val(root, user, db)
            else
                return val(el, root, user, db)
        else
            return val    

    setState = (result, el) ->
        for attr in perms
            if attr of auth
                result[attr] = resolve(auth[attr], el, attr)
            else if attr of prev
                result[attr] = prev[attr]
            else
                result[attr] = true
    
    copyState = (inState) ->
        state = {}
        for attr in perms
            state[attr] = inState[attr]
        state
        
    setState(result, doc)
    state = copyState(result)

    if type == Dict
        for key, val of schema
            if 'schema' of val
                result.children = {} if !('children' of result)
                if val.type == Dict
                    subdoc = if (key of doc) then doc[key] else {}
                    result.children[key] = _genAuth({}, val, subdoc, user, db, state, root)
                else if val.type == List
                    subdoc = if (key of doc) then doc[key] else []
                    result.children[key] = _genAuth({}, val, subdoc, user, db, state, root)
                else
                    throw new Error('Malformed schema, "schema" prop for non-Dict/List')
    else if type == List
        result.children = []
        for subdoc in doc
            state2 = copyState(state)
            setState(state2, subdoc)
            result.children.push(_genAuth({}, {schema:schema}, subdoc, user, db, state2, root))
    else
        throw new Error('Malformed document, needs to be Dict or List')
    
    result


class Auth
    constructor: (endpoint, doc, user, db) ->
        _genAuth(@, endpoint, doc, user, db)
        
    get: (path) ->
        current = @
        if path
            parts = path.split('.')        
            for part in parts
                if 'children' not of current
                    throw new Error('Nonexistent Auth path')
                if current.children instanceof Array
                    ind = parseInt(part)
                    current = current.children[ind]
                else                
                    if part not of current.children
                        throw new Error('Nonexistent Auth path')
                    current = current.children[part]
            
        return {
            create: current.create
            read:   current.read
            edit:   current.edit
            delete: current.delete
        }


module.exports = Auth
