logger = require('log4js').getLogger 'twitter-watcher-module'
config = require 'config'

TwitterWatcher = require '../TwitterWatcher'

_twitterWatcher = new TwitterWatcher config.get('twitter.userId'), config.get('twitter.settings')
_twitterWatcher.on 'tweet', (text, urlToTweet) ->
    logger.info 'tweet', urlToTweet, text
    _bot.announche_channel.sendMessage "(<#{urlToTweet}>)\n#{text}"

# TODO should probably handle error-event

_bot = null

# start stop logic
startTestModule = (bot, done) ->
    _bot = bot
    _twitterWatcher.startWatching()
    done()

stopTestModule = (done) ->
    _twitterWatcher.stopWatching()
    done()

module.exports = (bot, done) ->
    startTestModule bot, done
    return (doneStop) -> stopTestModule doneStop
