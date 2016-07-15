logger = require('log4js').getLogger 'botinfo-watcher-module'
_settings = require '../settings.json'

TillerinoStatusWatcher = require '../TillerinoStatusWatcher'

_tillerinoStatusWatcher = new TillerinoStatusWatcher _settings.tillerinoBotInfo.url, _settings.tillerinoBotInfo.neededSilenceForErrorSec

_tillerinoStatusWatcher.on 'connectedChanged', (connected) ->
    logger.info 'new connected value', connected
    if connected
        _bot.announche_channel.sendMessage 'Tillerinobot just disconnected :cry:'
    else
        _bot.announche_channel.sendMessage 'Tillerinobot connected :smile:'

_tillerinoStatusWatcher.on 'lastInteraction', (silence, delta) ->
    logger.info 'lastInteraction-event', silence, delta
    if silence
        _bot.announche_channel.sendMessage 'bot is ded'
    else
        _bot.announche_channel.sendMessage 'bot is not ded'
_tillerinoStatusWatcher.on 'ded', (ded) ->
    logger.info 'ded-event', ded
    if ded
        _bot.announche_channel.sendMessage 'bot is ded'
    else
        _bot.announche_channel.sendMessage 'bot is not ded'

_bot = null

botInfoHandler = (str, args, message, isAdmin) ->
    await message.channel.sendMessage('querying status...').then defer msg
    await _tillerinoStatusWatcher.queryBotInfo defer err, status
    if err
        logger.error 'error while querying', err
        message.channel.sendMessage 'error :cry:'
        return

    msg.edit "```       connected: #{status.connected}\nlast interaction: #{new Date(status.lastInteraction)}\n   running since: #{new Date(status.lastInteraction)}```"

# start stop logic
startTestModule = (bot, done) ->
    _bot = bot
    _bot.addListener 'command:botinfo', botInfoHandler
    _tillerinoStatusWatcher.startWatching _settings.tillerinoBotInfo.pollIntervalSec
    done()

stopTestModule = (done) ->
    _bot.removeListener 'command:botinfo', botInfoHandler
    _tillerinoStatusWatcher.stopWatching()
    done()

module.exports = (bot, done) ->
    startTestModule bot, done
    return (doneStop) -> stopTestModule doneStop
