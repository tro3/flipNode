p = console.log

module.exports = (env) ->
  # enforce ids
  # determine history
  # generate tid
  # save
  env.tid = '12345'
  if env.doc._id
    env.cache.update(env.collection, {_id:env.doc._id}, env.doc)
    .then (resp) -> env.mongoResponse = resp
  else
    env.cache.insert(env.collection, env.doc)
    .then (resp) -> env.mongoResponse = resp
