
q = require 'q'

x = module.exports

x.checkList = -> q.resolve(true)
x.checkDoc = -> q.resolve(true)