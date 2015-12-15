async = require('async')
util = require('util')
Q = require('q')


class Notificator
  @::defaultLanguage = 'en'
  @::channels = []
  @::events = null
  constructor:(@options = {})->
    @options.debug = @options.debug or no

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

  getTemplates:(event,channel,language,callback)->
    channel.getTemplates(event,language,(err,messages)->
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



  notify:(event,receiver,data,options,callback)->
    deferred = Q.defer()

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
      ,(err)->
        if err
          deferred.reject(err)
        else
          deferred.resolve()
      )
    )
    return deferred.promise.nodeify(callback)

  notifyDestination:(event,channelName,destination,data,options,callback)->
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

    channel = channelWrap.channel

    @sendMessage(event,channel,null,channel.wrappedDestination(destination),data,(err,info)->
      if err
        deferred.reject(err)
      else
        deferred.resolve(info)
    )
    return deferred.promise.nodeify(callback)



  sendMessage:(event,channel,receiver,destination,data,callback)->
    @getTemplates(event,channel,destination.language or @defaultLanguage,(err,templates)=>
      return callback(err) if err
      async.forEach(templates,(template,cb)=>
        message = @getMessageFromTemplate(template,receiver,destination,data)
        if @options.debug
          console.log('Notificator: sending message',message,', to',destination)
          async.nextTick(callback)
        else
          channel.sendMessage(message,destination,cb)
      ,callback)
    )

module.exports = Notificator