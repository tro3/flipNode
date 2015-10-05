q = require 'q'
fp = require 'flipFP'
schemaMerge = require './schemaMerge'
enforceSchema = require './enforceSchema'
saveItem = require './saveItem'
p = console.log


module.exports = updateItem = (env, newDoc) ->
  env.cache.findOne env.collection, {_id:newDoc._id}
  .then (oldDoc) ->
    return {errs:['Document not found']} if !oldDoc
    env.doc = schemaMerge env.endpoint, oldDoc, newDoc
    enforceSchema(env)
  .then (env) ->
    return q(env) if env.errs.length
    saveItem(env).then -> return env
