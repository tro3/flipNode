
express = require('express')
Primus = require('primus')
flip = require('../..')
endpoints = require('./endpoints')  

p = console.log

app = express()
db = flip.connect('mongodb://localhost:27017/app')

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

flip.prepDB db, endpoints


server = app.listen 5000, ->
    p 'Listening'

flip.startSocket server, api

#primus = new Primus(server, { transformer: 'SockJS' })
#primus.save('./primus.js')
# 
#
#    
# 
#primus.on 'connection', (spark) ->  
#  console.log('client ' + spark.id + ' has connected to the server')
#  spark.on 'data', (data) ->
#    console.log data
#    spark.write(data)
#  api.events.on 'edit.post', (req, res) ->
#    console.log 'trying'
#    spark.write (
#        action: 'edit'
#        collection: req.collection
#        id: req.id
#    )
