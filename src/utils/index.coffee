

# fn = (val, path) -> 
execTree = (obj, fn, path='') ->
    for key, val of obj
        fn(val, "#{path}#{key}")
        if val instanceof Array
            val.forEach (item, ind) ->
                fn(item, "#{path}#{key}.#{ind}")
                if typeof item == 'object'
                    execTree(item, fn, "#{path}#{key}.#{ind}.")
        else if typeof val == 'object'
            execTree(val, fn, "#{path}#{key}.")

# fn = (val, path) -> 
execValTree = (val, fn) ->
    wrapFn = (val, path) ->
        if typeof val != 'object'
            fn(val, path)
    execTree(val, wrapFn)



            
# fn = (element, path) -> 
execObjTree = (obj, fn, path='') ->
    npath = if path == '' then '' else "#{path}."
    for key, val of obj
        if val instanceof Array
            val.forEach (item, ind) ->
                if typeof item == 'object'
                    execObjTree(item, fn, "#{npath}#{key}.#{ind}")
        else if typeof val == 'object'
            execObjTree(val, fn, "#{npath}#{key}")
    fn(val, "#{path}")
    
    
module.exports.execTree = execTree
module.exports.execValTree = execValTree
module.exports.execObjTree = execObjTree
