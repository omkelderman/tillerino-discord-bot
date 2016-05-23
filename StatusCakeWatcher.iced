#current url = 'https://www.statuscake.com/App/Workfloor/PublicReportHandler.php?PublicID={publicId}&TestID={testId}'
#history url = 'https://www.statuscake.com/App/Workfloor/Get.Status.Perioids.php?PublicID={publicId}&VID={testId}'

request = require 'request'

setIntervalWithThis = (_this, func, msDelay, oArgs...) -> setInterval (()->func.apply _this, oArgs), msDelay

class StatusCakeWatcher extends process.EventEmitter
    constructor: (@publicId, @testId) ->
        @_getCurrentStatusURL = "https://www.statuscake.com/App/Workfloor/PublicReportHandler.php?PublicID=#{publicId}&TestID=#{testId}"
        @_getUptimeHistoryURL = "https://www.statuscake.com/App/Workfloor/Get.Status.Perioids.php?PublicID=#{publicId}&VID=#{testId}"

    _query: (url, cb) ->
        request.get {url: url, json: true}, (err, http, json) ->
            return cb err if err
            return cb new Error "status-cake-page response-code: #{http.statusCode}" if http.statusCode isnt 200
            return cb new Error 'no json respons' if typeof json isnt 'object'
            return cb null, json

    queryCurrentStatus: (cb) -> @_query @_getCurrentStatusURL, cb

    queryStatusHistory: (cb) -> @_query @_getUptimeHistoryURL, cb

    test: () -> setIntervalWithThis @, @kaas, 1000
    kaas: () -> console.log @_getCurrentStatusURL

    startWatching: (intervalSec, cb) ->
        await @queryCurrentStatus defer err, result
        if err
            logger.error 'could not query statuscake', err
            return cb err
        @name = result.SiteName
        @intervalId = setIntervalWithThis @, @_watchInterval, intervalSec*1000
        @_watchInterval()
        cb()

    _watchInterval: () ->
        await @queryStatusHistory defer err, result
        if err
            logger.error 'could not query statuscake', err
            # TODO do something smart
            return

        return if result.length is 0
        if @lastCheckId # not the first call
            return if @lastCheckId is result[0].StatusID # nothing changed

            @lastCheckId = result[0].StatusID
            @emit 'statusChange', @name, result[0], result[1] || {}
        else
            @lastCheckId = result[0].StatusID

    stopWatching: () ->
        clearInterval @intervalId if @intervalId

module.exports = StatusCakeWatcher
