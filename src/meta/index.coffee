
express = require('express')
views = require('./views')

module.exports = (api) ->
    router = express.Router()
    config = api.config

    router.get '/', (req, res) -> views.getAll(req, res, config)
    router
