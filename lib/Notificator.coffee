async = require('async')
util = require('util')
Q = require('q')


class Notificator
  @::defaultLanguage = 'en'
  @::channels = []
  @::events = null
  constructor:(@options = {})->
    @options.logging = @options.logging or no
    @defaultLanguage = @options.defaultLanguage if @options.defaultLanguage

  registerEvent:(event)->
    @events = @events or []
    @events.push(event)
  registerEvents:(events)->
    for event in events
      @registerEvent(event)

  addChannel:(name,channel)->
    @channels.push({name:name,channel:channel})
  getChannel:(name)->
    for channel in @channels
      if channel.name is name
        return channel
    return null

  getTemplates:(channel,info,callback)->
    channel.getTemplates(info,(err,messages)->
      return callback(err) if err
      if messages and not util.isArray(messages)
        messages = [messages]
      callback(null,messages)
    )

  getMessageFromTemplate:(template,receiver,destination,data)->
    data = data or {}
    if receiver
      data.receiver = receiver
    data.destination = destination
    return template.getMessage(data)



  notify:(event,receivers,data,options,callback)->
    deferred = Q.defer()

    if not Array.isArray(receivers)
      receivers = [receivers]

    if typeof data is 'function'
      callback = data
      data = options = undefined
    else if typeof options is 'function'
      callback = options
      options = undefined


    async.nextTick(()=>
      if @events and event not in @events
        return deferred.reject(new Error('unknown event ' + event))

      #      console.log(event,receiver,data,options,callback)
      data = data or {}
      data._event = event

      async.forEach(receivers,(receiver,cb)=>
        @log('Notificator: sending event:',event,', receiver:',receiver.toString())

        async.forEach(@channels,(channelWrap,cb)=>
          if util.isArray(options?.channels) and channelWrap.name not in options.channels
            return cb()
          channel = channelWrap.channel
          channel.getDestinations(receiver,(err,destinations)=>
            return cb(err) if err
            async.forEach(destinations,(destination,cb2)=>
              @sendMessage(event,channel,receiver,destination,data,cb2)
            ,cb)
          )
        ,cb)
      ,(err)->
        if err
          deferred.reject(err)
        else
          deferred.resolve()
      )
    )
    return deferred.promise.nodeify(callback)

  notifyDestination:(event,channelName,destinations,data,options,callback)->
    deferred = Q.defer()

    if typeof data is 'function'
      callback = data
      data = options = undefined
    else if typeof options is 'function'
      callback = options
      options = undefined

    channelWrap = @getChannel(channelName)
    if not channelWrap
      throw new Error('could not find channel \'' + channelName + '\'')

    if not Array.isArray(destinations)
      destinations = [destinations]

    async.map(destinations,(destination,cb)=>
      channel = channelWrap.channel
      wrappedDestination = channel.wrappedDestination(destination)

      @log('Notificator: notifying destination: event',event,'channel',channelName,', to',wrappedDestination)
      @sendMessage(event,channel,null,wrappedDestination,data,cb)
    ,(err,info)->
      if err
        deferred.reject(err)
      else
        if destinations.length is 0
          deferred.resolve(info[0])
        else
          deferred.resolve(info)
    )

    return deferred.promise.nodeify(callback)



  sendMessage:(event,channel,receiver,destination,data,callback)->
    info = {
      event: event,
      language: destination.language or @defaultLanguage,
      data: data
    }
    @getTemplates(channel,info,(err,templates)=>
      return callback(err) if err
      async.forEach(templates,(template,cb)=>
        message = @getMessageFromTemplate(template,receiver,destination,data)
        @log('Notificator: sending message to',destination.toString(),', data',JSON.stringify(message))
        if @options.dummy
          async.nextTick(cb)
        else
          channel.sendMessage(message,destination,cb)
      ,callback)
    )

  log:()->
    if @options.logging
      console.log.apply(console,arguments)

module.exports = Notificator