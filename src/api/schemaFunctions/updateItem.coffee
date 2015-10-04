q = require 'q'
fp = require 'flipFP'
schemaMerge = require './schemaMerge'
enforceSchema = require './enforceSchema'


updateItem = (req, newDoc) ->
  req.cache.findOne req.collection, {_id:newDoc._id}
  .then (oldDoc) ->
    return {errs:['Document not found']} if !oldDoc
    doc = schemaMerge req.endpoint, oldDoc, newDoc
    enforceSchema(req, doc)
  .then (result) ->
    return result if result.errs.length
    saveItem(req.collection, result.doc)  
