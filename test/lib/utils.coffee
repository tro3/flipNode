assert = require('chai').assert
p = console.log
x = module.exports

x.assertBody = (data, exp) ->
    assert.property data, '_tid'
    assert.typeOf data._tid, 'number'
    tmp = data._tid
    delete data._tid
    assert.deepEqual data, exp
    data._tid = tmp


x.equalArray = equalArray = (a, b) ->
  return false if !(a instanceof Array and b instanceof Array)
  return false if a.length != b.length
  for i in [0...a.length]
    if a[i] instanceof Array
      return false if !equalArray(a[i], b[i])
    else if typeof a[i] == 'object'
      return false if !equalObj(a[i], b[i])
    else
      return false if a[i] != b[i]
  true


keys = (x) -> if x then Object.keys(x).sort() else []

x.equalObj = equalObj = (a, b) ->
  return false if !(typeof a == 'object' and typeof b == 'object')
  return false if !(equalArray keys(a), keys(b))
  for i in keys a
    if a[i] instanceof Array
      return false if !equalArray(a[i], b[i])
    else if typeof a[i] == 'object'
      return false if !equalObj(a[i], b[i])
    else
      return false if a[i] != b[i]
  true
  
x.assertEqualObj = (a, b) ->
  if equalObj a, b
    return assert.isTrue true
  else
    return assert.deepEqual a, b