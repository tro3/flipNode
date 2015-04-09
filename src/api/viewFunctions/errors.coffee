

x = module.exports

x.NOT_FOUND =
    _status: 'ERR'
    _code: 404
    _msg: 'Not found'
 
x.MALFORMED =
    _status: 'ERR'
    _code: 400
    _msg: 'Malformed data'

x.ID_MISMATCH =
    _status: 'ERR'
    _code: 400
    _msg: 'ID mismatch'

x.UNAUTHORIZED =
    _status: 'ERR'
    _code: 403
    _msg: 'Unauthorized'

x.SERVER_ERROR = (msg) ->
    _status: 'ERR'
    _code: 500
    _msg: 'Server Error'
    _detail: msg
