logger = require('log4js').getLogger 'Bot'
Discordie = require('discordie');

String::startsWith         ?= (s) -> @[...s.length] is s
String::endsWith           ?= (s) -> s is '' or @[-s.length..] is s
String::compareIgnoreCase  ?= (s) -> s.toUpperCase() is @.toUpperCase()

class DiscordBot extends process.EventEmitter
    constructor: (settings) ->
        client = new Discordie(autoReconnect: true);
        @client = client
        @command_prefix = settings.command_prefix
        client.connect token: settings.token
        client.Dispatcher.on 'MESSAGE_CREATE', (e) =>
            @_handleMessage e.message if e.message
        client.Dispatcher.on 'GATEWAY_READY', (e) =>
            # get guild
            guild = client.Guilds.find (g) -> g.id is settings.guild_id
            return @emit 'error', 'could not find guild' if not guild
            @guild = guild

            # get announche channel
            announche_channel = guild.textChannels.find (tc) -> tc.name.compareIgnoreCase settings.announche_channel
            return @emit 'error', 'could not find text-channel' if not announche_channel
            @announche_channel = announche_channel

            # get admin-role
            admin_role = guild.roles.find (r) -> r.name.compareIgnoreCase settings.admin_role
            return @emit 'error', 'could not find admin-role' if not admin_role
            @admin_role = admin_role

            @botUser = client.User
            @emit 'ready', client.User.username
        client.Dispatcher.on 'DISCONNECTED', (e) =>
            # lets die for now, probably should do something better
            @emit 'error', e.error

    close: () -> @client.disconnect()

    _isMessageFromAdmin: (message) -> message.member.hasRole @admin_role

    _handleMessage: (message) ->
        #ignore our own messages
        return if message.author.id is @botUser.id

        adminMessage = @_isMessageFromAdmin message

        if message.isPrivate
            # dm
            @_handleDm message, adminMessage
        else
            # channel message
            if message.content.startsWith @command_prefix
                # command-message
                @_handleChannelCommandMessage message, adminMessage
            else
                # normal message
                @emit 'message', message, adminMessage

    _handleChannelCommandMessage: (message, adminMessage) ->
        @_emitCommandEvent message.content[@command_prefix.length..], 'channel', message, adminMessage

    _handleDm: (message, adminMessage) ->
        if message.content.startsWith @command_prefix
            @_emitCommandEvent message.content[@command_prefix.length..], 'dm', message, adminMessage
        else
            @_emitCommandEvent message.content, 'dm', message, adminMessage

    _emitCommandEvent: (commandString, prefix, message, adminMessage) ->
        argsIndex = commandString.indexOf ' '
        if argsIndex is -1
            # no args
            command = commandString
            argsString = ""
            args = []
        else
            command = commandString.substr 0, argsIndex
            argsString = commandString.substr(argsIndex+1).trim()
            args = argsString.split /\s+/

        # emit them events
        @emit "command:#{command}", argsString, args, message, adminMessage
        @emit "#{command}-command:#{command}", argsString, args, message, adminMessage
        if adminMessage
            @emit "command!:#{command}", argsString, args, message
            @emit "#{command}!-command:#{command}", argsString, args, message
        logger.debug '%shandle command %s-%s: [%s]', (if adminMessage then '!' else ''), prefix, command, argsString

module.exports = DiscordBot
