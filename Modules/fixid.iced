logger = require('log4js').getLogger 'statuscake-watcher-module'
request = require 'request'
config = require 'config'

TILLERINO_KEY = config.get 'tillerinokey'

_bot = null

getApiUrl = (id) -> "https://api.tillerino.org/userbyid?k=#{TILLERINO_KEY}&id=#{id}"

doApiRequest = (id, callback) ->
    logger.debug 'doing request for userid:', id
    url = getApiUrl id
    request.get {url: url, json: true}, (err, http, json) ->
        return callback err if err # request error
        return callback null if http.statusCode is 404 # not found
        return callback new Error "http statusCode #{http.statusCode}" if http.statusCode isnt 200 # other http error
        callback null, json.userId, json.userName

fixIdHandler = (str, args, message, isAdmin) ->
    id = parseInt args[0], 10
    return message.channel.sendMessage 'invalid id' if isNaN id
    return message.channel.sendMessage 'number too small' if id < 1
    doApiRequest id, (err, resultId, resultName) ->
        if err
            logger.error 'error while fixing id', err
            return message.channel.sendMessage 'whoops, something went wrong :cry:'

        return message.channel.sendMessage 'that user could not be found' if resultName is undefined

        message.channel.sendMessage "ID `#{resultId}` belongs to user `#{resultName}`! That user should now be able to use the bot without errors :smile:"

# start stop logic
startFixIDModule = (bot, done) ->
    _bot = bot
    _bot.addListener 'command:fixid', fixIdHandler
    done()

stopFixIDModule = (done) ->
    _bot.removeListener 'command:fixid', fixIdHandler
    done()

module.exports = (bot, done) ->
    startFixIDModule bot, done
    return (doneStop) -> stopFixIDModule doneStop
