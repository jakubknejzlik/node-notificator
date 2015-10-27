swig = require('swig')

class ChannelTemplate
  getMessage:(data)->
    result = {}
    _data = JSON.parse(JSON.stringify(data))
    _data._data = JSON.parse(JSON.stringify(data))
    for key,value of @
      if typeof value is 'string'
        value = swig.render(value,{locals:_data})
        result[key] = value
      else
        result[key] = value
    return result


class NotificatorChannel
  constructor:(@options = {})->
    if not @options.getDestinations
      @options.getDestinations = (obj,callback)->
        callback(new Error('options.getDestinations not specified'))
    if not @options.getTemplates
      @options.getTemplates = (obj,callback)->
        callback(new Error('options.getTemplates not specified'))

  getDestinations:(receiver,callback)->
    @options.getDestinations(receiver,(err,destinations)=>
      return callback(err) if err
      try
        for destination in destinations
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
    return yes
  validateTemplate:(template)->
    if template not instanceof ChannelTemplate
      throw new Error('template must be instance of ChannelTemplate')
    return yes

NotificatorChannel.ChannelTemplate = ChannelTemplate

module.exports = NotificatorChannel