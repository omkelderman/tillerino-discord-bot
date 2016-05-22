
_bot = null

pingHandler = (str, args, message, isAdmin) -> message.channel.sendMessage 'pong!'
echoHandler = (str, args, message) -> message.channel.sendMessage "#{message.author.mention}: #{str}"

# start stop logic
startTestModule = (bot, done) ->
    _bot = bot
    _bot.addListener 'command:ping', pingHandler
    _bot.addListener 'command!:echo', echoHandler
    done()

stopTestModule = (done) ->
    _bot.removeListener 'command:ping', pingHandler
    _bot.removeListener 'command!:echo', echoHandler
    done()

module.exports = (bot, done) ->
    startTestModule bot, done
    return (doneStop) -> stopTestModule doneStop
