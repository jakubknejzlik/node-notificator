async = require('async')
util = require('util')
Q = require('q')

class Notificator
  @::defaultLanguage = 'en'
  @::channels = []
  @::events = []
  constructor:(@options = {})->

  registerEvent:(event)->
    @events.push(event)
  registerEvents:(events)->
    for event in events
      @registerEvent(event)

  addChannel:(name,channel)->
    @channels.push({name:name,channel:channel})

  getTemplates:(event,channel,language,callback)->
    channel.getTemplates(event,language,(err,messages)->
      return callback(err) if err
      if messages and not util.isArray(messages)
        messages = [messages]
      callback(null,messages)
    )

  getMessageFromTemplate:(template,receiver,destination,data)->
    data = data or {}
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
      if event not in @events
        return deferred.reject(new Error('unknown event ' + event))

#      console.log(event,receiver,data,options,callback)
      data = data or {}
      data._event = event

      async.forEach(@channels,(channel,cb)=>
        if util.isArray(@options.channels) and channel.name not in @options.channels
          return cb()
        _channel = channel.channel
        _channel.getDestinations(receiver,(err,destinations)=>
          return cb(err) if err
          async.forEach(destinations,(destination,cb2)=>
            @getTemplates(event,_channel,destination.language or @defaultLanguage,(err,templates)=>
              return cb(err) if err
              async.forEach(templates,(template,cb)=>
                message = @getMessageFromTemplate(template,receiver,destination,data)
                channel.channel.sendMessage(message,destination,cb)
              ,cb2)
            )
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

module.exports = Notificator