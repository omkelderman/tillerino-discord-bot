logger = require('log4js').getLogger 'troll-module'
config = require 'config'

TROLL_CHANNEL = config.get 'discord.troll_channel'
TROLL_PREFIX = config.get 'discord.troll_prefix'

_bot = null

# following lines are already loaded in DiscordBot.iced
#String::compareIgnoreCase  ?= (s) -> s.toUpperCase() is @.toUpperCase()
#String::startsWith         ?= (s) -> @[...s.length] is s


rawHandler = (message, isAdmin) ->
    logger.debug '[%s] %s', message.channel.name, message.content

    # dont care about messages not in troll-channel
    return if not message.channel.name.compareIgnoreCase TROLL_CHANNEL

    # message is "ok"
    return if message.content.startsWith TROLL_PREFIX

    # message is not "ok", lets remove it :P
    message.delete()

# start stop logic
startTestModule = (bot, done) ->
    _bot = bot
    _bot.addListener 'raw', rawHandler
    done()

stopTestModule = (done) ->
    _bot.removeListener 'raw', rawHandler
    done()

module.exports = (bot, done) ->
    startTestModule bot, done
    return (doneStop) -> stopTestModule doneStop
