
_bot = null

sections =
    reset: "the-bot-says-its-out-of-recommendations-what-do"
    pp: "i-was-promised-some-pp-where-are-they"
    futureyou: "what-does-future-you-mean"
    mutual: "mutual-me-pls"
    std: "does-this-work-for-other-game-modes-than-standard"
    fixid: "the-bot-tells-me-my-username-is-confusing-halp"

faqHandler = (str, args, message, isAdmin) ->
    section = sections[args[0]]
    args.shift() if section

    url = 'https://github.com/Tillerino/Tillerinobot/wiki/FAQ'
    url += '#'+section if section
    url = "<#{url}>"

    mention = args[0] + ': ' if args[0]
    prefix = 'The FAQ has really usefull information! ' if not section

    # array-join 'hack' to not get 'undefined' in result string :P
    message.channel.sendMessage [mention, prefix, url].join ''

listHandler = (str, args, message, isAdmin) ->
    str = '```\n'
    for key, value of sections
        str += key + ' -> #' + value + '\n'
    str += '```'
    message.channel.sendMessage str

# start stop logic
startTestModule = (bot, done) ->
    _bot = bot
    _bot.addListener 'command:faq', faqHandler
    _bot.addListener 'command:faqlist', listHandler
    done()

stopTestModule = (done) ->
    _bot.removeListener 'command:faq', faqHandler
    _bot.removeListener 'command:faqlist', listHandler
    done()

module.exports = (bot, done) ->
    startTestModule bot, done
    return (doneStop) -> stopTestModule doneStop
