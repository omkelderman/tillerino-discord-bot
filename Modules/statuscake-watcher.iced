logger = require('log4js').getLogger 'statuscake-watcher-module'
_settings = require '../settings.json'

StatusCakeWatcher = require '../StatusCakeWatcher'

_statusCakeWatcher = new StatusCakeWatcher _settings.statuscake.publicId, _settings.statuscake.testId
_statusCakeWatcher.on 'statusChange', (name, newS, oldS) ->
    logger.info 'new status', name, newS, oldS
    _bot.announche_channel.sendMessage "[*#{name}*] New status: **#{newS.Status}**. Last status was: **#{oldS.Status}** for **#{oldS.Period}**"

_bot = null

banchoStatusHandler = (str, args, message, isAdmin) ->
    await message.channel.sendMessage('querying status...').then defer msg
    await _statusCakeWatcher.queryCurrentStatus defer err, status
    if err
        logger.error 'error while querying', err
        message.channel.sendMessage 'error :cry:'
        return

    msg.edit "**#{status.SiteName}** is **#{status.Status}** (7 day uptime of %#{status.Uptime})"

# start stop logic
startTestModule = (bot, done) ->
    _bot = bot
    _bot.addListener 'command:bancho-status', banchoStatusHandler
    _statusCakeWatcher.startWatching _settings.statuscake.pollIntervalSec, done

stopTestModule = (done) ->
    _bot.removeListener 'command:bancho-status', banchoStatusHandler
    _statusCakeWatcher.stopWatching()
    done()

module.exports = (bot, done) ->
    startTestModule bot, done
    return (doneStop) -> stopTestModule doneStop
