
deepDiff = require('deep-diff')

p = console.log



join = (path, key) ->
    if path.trim().length > 0
        "#{path}.#{key}"
    else
        key

arrVal = (item) -> if typeof item == 'object' then item._id else item

arraysEqual = (a, b) ->
    if (a.length != b.length)
        return false
    for i in [0...a.length]
        if a[i] != b[i]
            return false
    return true


module.exports = diff = (o, n, path='') ->
    results = []

    oKeys = Object.keys(o)
    oKeys.sort()
    nKeys = Object.keys(n)
    nKeys.sort()
    
    for key in oKeys
        if key in nKeys
            if o[key] instanceof Array && n[key] instanceof Array
                oVals = (arrVal(x) for x in o[key])
                nVals = (arrVal(x) for x in n[key])
                oInd = 0
                nInd = 0
                adds = []
                rems = []
                while oInd < oVals.length || nInd < nVals.length
                    if nInd < nVals.length && oVals.indexOf(nVals[nInd]) == -1
                        adds.push nInd
                        nInd +=1
                    else if oInd < oVals.length && nVals.indexOf(oVals[oInd]) == -1
                        rems.push oInd
                        oInd += 1
                    else
                        oInd += 1
                        nInd += 1
                adds.forEach (ind) -> nVals.splice(ind,1)
                rems.forEach (ind) -> oVals.splice(ind,1)
                rems.forEach (ind) ->
                    results.push
                        action: 'item removed'
                        objPath: path
                        field: key
                        index: ind
                        old: o[key][ind]                
                if !arraysEqual(oVals, nVals)
                    results.push
                        action: 'items reordered'
                        objPath: path
                        field: key
                        old: oVals
                        new: nVals
                adds.forEach (ind) ->
                    results.push
                        action: 'item added'
                        objPath: path
                        field: key
                        index: ind
                        new: n[key][ind]

            else if typeof o[key] == 'object' && typeof n[key] == 'object' && o[key] != null && n[key] != null
                results = results.concat diff o[key], n[key], join path, key

            else if o[key] != n[key]
                results.push
                    action: 'field changed'
                    objPath: path
                    field: key
                    old: o[key]
                    new: n[key]

        else
            results.push
                action: 'field removed'
                objPath: path
                field: key
                old: o[key]

    for key in nKeys
        if !(key in oKeys)
            results.push
                action: 'field added'
                objPath: path
                field: key
                new: n[key]

    results

