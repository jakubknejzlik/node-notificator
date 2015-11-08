swig = require('swig')


class Destination
  constructor:(@destination,@language = null)->


class ChannelTemplate

  getMessage:(data)->
    _data = JSON.parse(JSON.stringify(data))
    _data._data = JSON.parse(JSON.stringify(data))
    return @parseObjectValues(@,_data)

  parseObjectValues:(object,data)->
    result = {}
    for key,value of object
      if typeof value is 'object'
        result[key] = @parseObjectValues(value,data)
      else if typeof value is 'string'
        value = swig.render(value,{locals:data})
        result[key] = value
      else if typeof value isnt 'function'
        result[key] = value
    return result


class NotificatorChannel
  constructor:(@options = {})->
    if not @options.getDestinations
      @options.getDestinations = (obj,callback)->
        callback(new Error('options.getDestinations not specified'))
    if not @options.getTemplates
      @options.getTemplates = (obj,language,callback)->
        callback(new Error('options.getTemplates not specified'))

  getDestinations:(receiver,callback)->
    @options.getDestinations(receiver,(err,destinations)=>
      return callback(err) if err
      try
        for destination in destinations
          if destination not instanceof Destination
            destination = new Destination(destination)
          @validateDestination(destination)
        callback(null,destinations)
      catch err
        callback(err)
    )

  getTemplates:(event,language,callback)->
    @options.getTemplates(event,language,(err,template)=>
      return callback(err) if err
      if not template
        template = @options.defaultTemplate
      try
        @validateTemplate(template)
        callback(null,template)
      catch err
        callback(err)
    )

  sendMessage:(message,destination,callback)->
    return callback(new Error('sendMessage not implemented'))

  validateDestination:(destination)->
    return destination instanceof Destination
  validateTemplate:(template)->
    if template not instanceof ChannelTemplate
      throw new Error('template must be instance of ChannelTemplate')
    return yes

NotificatorChannel.ChannelTemplate = ChannelTemplate
NotificatorChannel.Destination = Destination


module.exports = NotificatorChannel