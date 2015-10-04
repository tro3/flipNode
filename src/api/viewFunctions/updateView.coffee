
auth = require '../authFunctions'


updateView = (req, res) ->
  return res.status(400).send(errors.MALFORMED) if 'body' not of req
  auth.checkList('edit', req.endpoint, req)
  .then (auth) ->
    return res.status(403).send(errors.UNAUTHORIZED) if not auth
    return res.status(400).send(errors.ID_MISMATCH) if req.body._id != parseInt(req.params.id)
    auth.checkDoc('edit', req.endpoint, req.body._id, req)
  .then (auth) ->
    return res.status(403).send(errors.UNAUTHORIZED) if not auth
    updateItem(req.endpoint, req.body, req)
  .then (result) ->
    return res.status(200).send(serializeErrors(result)) if result.errs.length
    return res.status(200).send(serializeDoc(req, result.doc))

