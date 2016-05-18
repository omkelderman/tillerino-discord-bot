logger = require('log4js').getLogger 'ModuleSystem'
fs = require 'fs'
path = require 'path'

# TODO if some kind of semaphore in the start and stop logic

module.exports = ModuleSystem =
    # all the running modules
    running: {}

    init: (dir, bot) ->
        @dir = dir if dir
        @dirName = path.basename dir
        @bot = bot if bot

    _toRequireName: (name) -> "./#{@dirName}/#{name}"

    _scanDir: (cb) ->
        await fs.readdir @dir, defer err, files
        return cb err if err
        available = files.map (name) -> name.replace '.iced', ''
        cb null, available

    # start 'name' if not already started
    start: (name, cb) ->
        # if exists in running, return
        return cb 'module is already started' if @running[name]

        # otherwise start it
        # logger.debug "[fake] starting module #{name}"
        # @running[name] = 'kaas'
        # cb()

        logger.info "starting module #{name}"
        try
            module = require @_toRequireName name
            await @running[name] = module @bot, defer err
            if err
                logger.info "module #{name} started with err", err
            else
                logger.info "module #{name} started"

            cb err
        catch error
            logger.info "module #{name} does not exists", err
            cb error

    # stop 'name' if not already stopped
    stop: (name, cb) ->
        # if not exists in running, return
        return cb 'module does not exists' if not @running[name]

        # otherwise stop it
        logger.info "stopping module #{name}"
        await @running[name] defer err
        if err
            logger.info "module #{name} stopped with err", err
        else
            logger.info "module #{name} stopped"

        # delete it in our own cache
        delete @running[name]

        # delete it in global require cache
        delete require.cache[require.resolve(@_toRequireName(name))]

        cb err

    startAll: (cb) ->
        # calls start on everything in available
        await @_scanDir defer err, available
        return cb false if err

        started = []
        for name in available
            await @start name, defer err
            if err
                logger.warn "Error while starting module #{name}"
            else
                started.push name

        cb started

    stopAll: (cb) ->
        # calls stop on eveything in running
        stopped = []
        for name in Object.keys @running
            await @stop name, defer err
            if err
                logger.warn "Error while stopping module #{name}"
            else
                stopped.push name

        cb stopped
