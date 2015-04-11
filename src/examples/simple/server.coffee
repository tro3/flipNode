
express = require('express')
flip = require('..')
endpoints = require('./endpoints')  

p = console.log

app = express()
db = flip.connect('mongodb://localhost:27017/app')

app.use '/', (req,res,next) ->
    p req.method, req.url
    next()

app.get '/', (req, res) ->
    res.sendfile('./index.html')

api = flip.api db, endpoints
app.use '/api', api
app.use '/meta', flip.meta(api)

flip.prepDB db, endpoints
server = app.listen 5000, ->
    p 'Listening'