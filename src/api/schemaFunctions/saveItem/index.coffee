fp = require 'flipFP'
diff = require '../../viewFunctions/diff'
p = console.log



genTID =  (env) ->
    env.tid = Math.random().toString()[2..]
    env


addHist = (env) ->
  if env.doc._id
    hist = fp.map (fp.merge {collection: env.collection, item: env.doc._id}),
      diff(env.original, env.doc)
    env.cache.insert 'flipData.history', hist

saveToDB = (env) ->
  if env.doc._id
    env.cache.update(env.collection, {_id:env.doc._id}, env.doc)
    .then (resp) -> env.mongoResponse = resp
  else
    env.cache.insert(env.collection, env.doc)
    .then (resp) -> env.mongoResponse = resp


module.exports = (env) ->
  genTID(env)
  saveToDB(env)
  .then -> #Check for error
    addHist(env)