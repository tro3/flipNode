
express = require('express')
Primus = require('primus')
flip = require('../..')
endpoints = require('./endpoints')  

p = console.log

app = express()
db = flip.connect('mongodb://localhost:27017/app')
flip.prepDB db, endpoints

app.use '/', (req,res,next) ->
    p req.method, req.url
    next()

app.get '/', (req, res) ->
    res.sendfile('./index.html')

app.get '/lib/primus.js', (req, res) ->
    res.sendfile('./primus.js')

api = flip.api db, endpoints
app.use '/api', api
app.use '/meta', flip.meta(api)


server = app.listen 5000, ->
    p 'Listening'

flip.startSocket server, api

