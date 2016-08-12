logger = require('log4js').getLogger 'simple-message-module'
config = require 'config'
_redis = require 'redis'
_redisClient = null
_bot = null

REDIS_PREFIX = config.get 'redis.prefix'

redisErrorHandler = (err, discordChannel) ->
    logger.error 'redis error', err
    discordChannel.sendMessage "Redis err: #{err}" if discordChannel

addSimpleHandler = (str, args, message) ->
    m = str.match /(\S*) (.+)/
    if m and (x = m[2].trim())
        logger.debug 'message or something', x
        _redisClient.set "simple:#{m[1]}", x, (err, resp) ->
            return redisErrorHandler err, message.channel if err
            message.channel.sendMessage "command #{_bot.command_prefix}#{m[1]} probably added (or changed): #{resp}"
    else
        message.channel.sendMessage 'im confused...'

delSimpleHandler = (str, args, message) ->
    #del
    if args[0]
        _redisClient.del "simple:#{args[0]}", (err, resp) ->
            return redisErrorHandler err, message.channel if err
            message.channel.sendMessage "command #{_bot.command_prefix}#{args[0]} probably deleted: #{resp}"
    else
        message.channel.sendMessage 'im confused...'

allHandler = (command, argsString, args, message, adminMessage) ->
    _redisClient.get "simple:#{command}", (err, resp) ->
        return redisErrorHandler err, message.channel if err
        return if not resp
        prefix = if args[0] then "#{args[0]}: " else ''
        message.channel.sendMessage "#{prefix}#{resp}"

listSimpleHandler = (argsString, args, message, adminMessage) ->
    prefix = "#{REDIS_PREFIX}simple:"
    prefixLen = prefix.length
    _redisClient.keys "#{prefix}*", (err, resp) ->
        return redisErrorHandler err, message.channel if err
        list = resp.map (x) -> _bot.command_prefix + x.slice prefixLen
        message.channel.sendMessage "#{message.author.mention}: #{list.join ', '}"

# start stop logic
startTestModule = (bot, done) ->
    _bot = bot
    _bot.addListener 'command!:addsimple', addSimpleHandler
    _bot.addListener 'command!:delsimple', delSimpleHandler
    _bot.addListener 'command:listsimple', listSimpleHandler
    _bot.addListener 'command', allHandler

    # debug redis stuff
    _redisClient = _redis.createClient config.get 'redis'
    _redisClient.on 'error', (err) -> redisErrorHandler err
    _redisClient.on 'ready', () ->
        logger.info 'redis connection ready'
    done()

stopTestModule = (done) ->
    _bot.removeListener 'command!:addsimple', addSimpleHandler
    _bot.removeListener 'command!:delsimple', delSimpleHandler
    _bot.removeListener 'command:listsimple', listSimpleHandler
    _bot.removeListener 'command', allHandler
    _redisClient.once 'end', done
    _redisClient.quit()

module.exports = (bot, done) ->
    startTestModule bot, done
    return (doneStop) -> stopTestModule doneStop
