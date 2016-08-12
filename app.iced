config = require 'config'
path = require 'path'
fs= require 'fs'
MODULE_DIR = path.resolve __dirname, config.get 'moduleDir'
LOG_DIR = path.resolve __dirname, config.get 'logDir'

# string extensions
String::startsWith         ?= (s) -> @[...s.length] is s
String::endsWith           ?= (s) -> s is '' or @[-s.length..] is s
String::compareIgnoreCase  ?= (s) -> s.toUpperCase() is @.toUpperCase()

# init logging crap
log4js = require 'log4js'
try
    fs.mkdirSync LOG_DIR
catch error
    if error.code isnt 'EEXIST'
        console.error 'Could not create log-dir', error
        process.exit 1
log4js.configure config.get('log4js'), cwd: LOG_DIR
logger = log4js.getLogger 'app'
# all done, start all the other stuff

logger.info "starting app with pid #{process.pid}"

# connect to discord
bot = new (require('./DiscordBot')) config.get 'discord'
await bot.once 'ready', defer botUsername
logger.info 'bot ready', botUsername

# init module system
ModuleSystem = require './ModuleSystem'
ModuleSystem.init MODULE_DIR, bot

# start modules on startup
logger.info 'starting all modules'
await ModuleSystem.startAll defer()
logger.info 'all modules should be started'

# everything should be ready now :D

###################### start of start/stop/restart logic ######################

startModule = (name, channel, cb) ->
    await ModuleSystem.start name, defer err
    if err
        channel.sendMessage "could not start module #{name}"
    else
        channel.sendMessage "started module #{name}"
    cb() if cb
stopModule = (name, channel, cb) ->
    await ModuleSystem.stop name, defer err
    if err
        channel.sendMessage "could not stop module #{name}"
    else
        channel.sendMessage "stopped module #{name}"
    cb() if cb

bot.on 'command!:start', (str, args, message) ->
    for name in args
        await startModule name, message.channel, defer()

bot.on 'command!:stop', (str, args, message) ->
    for name in args
        await stopModule name, message.channel, defer()

bot.on 'command!:restart', (str, args, message) ->
    for name in args
        await stopModule name, message.channel, defer()
        await startModule name, message.channel, defer()

startAll = (channel, cb) ->
    await ModuleSystem.startAll defer started
    channel.sendMessage "started all modules: [#{started.join ', '}]"
    cb() if cb

stopAll = (channel, cb) ->
    await ModuleSystem.stopAll defer stopped
    channel.sendMessage "stopped all modules: [#{stopped.join ', '}]"
    cb() if cb

bot.on 'command!:startAll', (str, args, message) -> startAll message.channel
bot.on 'command!:stopAll', (str, args, message) -> stopAll message.channel
bot.on 'command!:restartAll', (str, args, message) -> stopAll message.channel, -> startAll message.channel

####################### end of start/stop/restart logic #######################

# on both SIGINT and SIGTERM start shutting down gracefully
process.on 'SIGINT', -> process.emit 'requestShutdown'
process.on 'SIGTERM', -> process.emit 'requestShutdown'

logger.info 'startup procedure done :D'

# shutdown procedure
process.once 'requestShutdown', ->
    process.on 'requestShutdown', -> logger.warn "Process (#{process.pid}) already shutting down gracefully..."
    logger.info 'shutting down gracefully...'

    # stop modules #
    logger.info 'stopping all modules'
    await ModuleSystem.stopAll defer()
    logger.info 'all modules should be stopped'


    # stop bot
    bot.close()
