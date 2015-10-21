async = require('async')
util = require('util')

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

  getTemplate:(messageId,channel,language,callback)->
    channel.getTemplate(messageId,language,(err,message)->
      return callback(err) if err
      callback(null,message)
    )

  parseTemplate:(template,receiver,data)->
    data = data or {}
    data.receiver = receiver
    return template.parsedData(data)



  notify:(event,receiver,data,options,callback)->
    if typeof data is 'function'
      callback = data
      data = options = undefined
    else if typeof options is 'function'
      callback = options
      options = undefined
    if event not in @events
      return callback(new Error('unknown event ' + event))

    console.log(event,receiver,data,options,callback)
    data = data or {}

    async.forEach(@channels,(channel,cb)=>
      if util.isArray(@options.channels) and channel.name not in @options.channels
        return cb()
      _channel = channel.channel
      _channel.getDestinations(receiver,(err,destinations)=>
        return cb(err) if err
        async.forEach(destinations,(destination,cb)=>
          @getTemplate(event,_channel,destination.language or @defaultLanguage,(err,event)=>
            return cb(err) if err
            message = @parseTemplate(event,receiver,data)
            console.log(message,destination)
            channel.channel.sendMessage(message,destination,cb)
          )
        ,cb)
      )
    ,callback)

module.exports = Notificator