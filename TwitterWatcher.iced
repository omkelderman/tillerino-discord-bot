logger = require('log4js').getLogger 'TwitterWatcher'
Twitter = require 'twitter'

class TwitterWatcher extends process.EventEmitter
    constructor: (@userId, twitterClientSettings) ->
        @twitterClient = new Twitter twitterClientSettings

    startWatching: () ->
        logger.info 'start watching'
        @stream = @twitterClient.stream 'statuses/filter', follow: @userId
        @stream.on 'data', (tweet) =>
            # return if not tweet from user and maybe random useless check, whatever :p
            return if not tweet.text or not tweet.user or tweet.user.id_str isnt @userId

            # return if it starts with a mention to someone else and is not a reply to outself or not a reply at all
            return if not(tweet.text[0] isnt '@' or not tweet.in_reply_to_user_id_str or tweet.in_reply_to_user_id_str is @userId)

            # tweet allowed!
            urlToTweet = "https://twitter.com/#{tweet.user.screen_name}/status/#{tweet.id_str}"
            text = tweet.text

            # replace url-entities
            if tweet.entities and tweet.entities.urls and tweet.entities.urls.length
                for urlEntitiy in tweet.entities.urls
                    text = text.replace urlEntitiy.url, urlEntitiy.expanded_url

            # fetch extended-media-entities
            extendedMediaEnities = {}
            if tweet.extended_entities and tweet.extended_entities.media and tweet.extended_entities.media.length
                for extendedMediaEntity in tweet.extended_entities.media
                    url = extendedMediaEntity.url
                    extendedMediaEnities[url] = [] if not extendedMediaEnities[url]
                    extendedMediaEnities[url].push extendedMediaEntity.media_url_https

            # replace extended-media-entities
            for url, imgUrls of extendedMediaEnities
                text = text.replace url, imgUrls.join ' '

            # replace media-entities
            if tweet.entities and tweet.entities.media and tweet.entities.media.length
                for mediaEntity in tweet.entities.media
                    if not extendedMediaEnities[mediaEntity.url]
                        # if somehow the extendedMediaEnities wasnt enough... :P
                        text = text.replace mediaEntity.url, mediaEntity.media_url_https

            @emit 'tweet', text, urlToTweet

        @stream.on 'end', (response) ->
            logger.warn 'HALP, should probably do something, this thing ended or something...'

        @stream.on 'error', (err) => @emit 'error', err

    stopWatching: () ->
        logger.info 'start watching'
        @stream.destroy()

module.exports = TwitterWatcher

###

{ created_at: 'Fri Jul 08 19:08:24 +0000 2016',
  id: 751493151655944200,
  id_str: '751493151655944192',
  text: 'test tweet with url https://t.co/2R6waMMbEZ lalalala',
  source: '<a href="http://twitter.com" rel="nofollow">Twitter Web Client</a>',
  truncated: false,
  in_reply_to_status_id: null,
  in_reply_to_status_id_str: null,
  in_reply_to_user_id: null,
  in_reply_to_user_id_str: null,
  in_reply_to_screen_name: null,
  user: { ... },
  geo: null,
  coordinates: null,
  place: null,
  contributors: null,
  is_quote_status: false,
  retweet_count: 0,
  favorite_count: 0,
  entities:
   { hashtags: [],
     urls: [ [Object] ],
     user_mentions: [],
     symbols: [] },
  favorited: false,
  retweeted: false,
  possibly_sensitive: false,
  filter_level: 'low',
  lang: 'tl',
  timestamp_ms: '1468004904079' }
###
