logger = require('log4js').getLogger 'TillerinoStatusWatcher'

request = require 'request'

setIntervalWithThis = (_this, func, msDelay, oArgs...) -> setInterval (()->func.apply _this, oArgs), msDelay

class TillerinoStatusWatcher extends process.EventEmitter
    constructor: (url, neededLastInteractionSilenceSec) ->
        @REQUEST_OPTIONS =
            url: url
            json: true
        @neededLastInteractionSilenceMs = neededLastInteractionSilenceSec*1000

    startWatching: (intervalSec) ->
        logger.info 'start watching'
        @lastBotInfo = undefined
        @_watchInterval()
        @intervalId = setIntervalWithThis @, @_watchInterval, intervalSec*1000

    stopWatching: () ->
        logger.info 'stop watching'
        clearInterval @intervalId if @intervalId

    _watchInterval: () ->
        await @queryBotInfo defer err, botInfo
        if err && (err.code isnt 'ECONNREFUSED') && (err.code isnt 'ECONNRESET')
            logger.error 'could not query tillerino-botinfo', err
            @emit 'request-error', err
            # TODO do something smart
            return

        if err
            # connection problem!
            if not @conRefusedWarningGiven
                # give ded-error
                @conRefusedWarningGiven = true
                @emit 'ded', true
        else
            # bot is reachable hype :D
            if @conRefusedWarningGiven
                # ded-error was given, unded-message plz
                @conRefusedWarningGiven = false
                @emit 'ded', false

            # connectedChanged-event, on connected-prop change, and on first run if connected is false
            if (@lastBotInfo && (@lastBotInfo.connected isnt botInfo.connected)) || not botInfo.connected
                @emit 'connectedChanged', botInfo.connected

            # lastInteraction-event, can always fire regardles of first run or not
            delta = Date.now() - botInfo.lastInteraction
            if (delta >= @neededLastInteractionSilenceMs) && (not @lastInteractionDeltaWarningGiven)
                # lastInteraction-silence bigger then given value
                @lastInteractionDeltaWarningGiven = true
                @emit 'lastInteraction', true, delta
            else if (delta < @neededLastInteractionSilenceMs) && @lastInteractionDeltaWarningGiven
                # lastInteraction-silence is smaller then given value again
                @lastInteractionDeltaWarningGiven = false
                @emit 'lastInteraction', false, delta

            @lastBotInfo = botInfo

    queryBotInfo: (cb) ->
        await request.get @REQUEST_OPTIONS, defer err, http, json
        return cb err if err
        return cb new Error "tillerino-botinfo response-code: #{http.statusCode}" if http.statusCode isnt 200
        return cb new Error 'tillerino-botinfo no json respons' if typeof json isnt 'object'
        return cb null, json

module.exports = TillerinoStatusWatcher
