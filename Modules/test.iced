
_bot = null

pingHandler = (str, args, message, isAdmin) -> message.channel.sendMessage 'pong!'
echoHandler = (str, args, message) -> message.channel.sendMessage "#{message.author.mention}: #{str}"
messageHandler = (message, isAdmin) ->
    if message.content.toLowerCase() is 'hi'
        message.channel.sendMessage "hi hi!"

# start stop logic
startTestModule = (bot, done) ->
    _bot = bot
    _bot.addListener 'command:ping', pingHandler
    _bot.addListener 'command!:echo', echoHandler
    _bot.addListener 'message', messageHandler
    done()

stopTestModule = (done) ->
    _bot.removeListener 'command:ping', pingHandler
    _bot.removeListener 'command!:echo', echoHandler
    _bot.removeListener 'message', messageHandler
    done()

module.exports = (bot, done) ->
    startTestModule bot, done
    return (doneStop) -> stopTestModule doneStop
