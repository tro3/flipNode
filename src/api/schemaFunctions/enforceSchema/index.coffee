
fp = require 'flipFP'
prim = require './primitives'
p = console.log

functions = [
  'enforceTypes'
  'enforceAllowed'
  'enforceRequired'
  'enforceUnique'
]

getMod = (name) -> require("./#{name}")

module.exports = enforceSchema = fp.pipe.apply(null, fp.map(getMod, functions))
