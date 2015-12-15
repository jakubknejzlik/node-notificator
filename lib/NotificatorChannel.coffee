swig = require('swig')
util = require('util')

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
      if value is null or not value
        result[key] = null
      else if typeof value is 'object'
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

  wrappedDestination:(destination)->
    if destination not instanceof Destination
      if typeof destination isnt 'string'
        destination = new Destination(destination.destination,destination.language or destination.lang)
      else
        destination = new Destination(destination)
    return destination


  getDestinations:(receiver,callback)->
    @options.getDestinations(receiver,(err,_destinations)=>
      return callback(err) if err
      try
        destinations = []
        for destination in _destinations
          if typeof destination is 'object'
            destination = Object.create(destination)
          if destination
            destination = @wrappedDestination(destination)
          @validateDestination(destination)
          destinations.push(destination)
        callback(null,destinations)
      catch err
        callback(err)
    )

  getTemplates:(event,language,callback)->
    @options.getTemplates(event,language,(err,templates)=>
      return callback(err) if err

      templates = templates or []
      if templates and not Array.isArray(templates)
        templates = [templates]

      templates = templates.filter((x)->
        return x
      )

      if templates.length is 0 and @options.defaultTemplate
        templates = [@options.defaultTemplate]
      try
        transformedTemplates = []
        for template in templates
          transformedTemplates.push(@transformTemplate(template))
        for template in transformedTemplates
          @validateTemplate(template)
        @debug('gottemplates',transformedTemplates)
        callback(null,transformedTemplates)
      catch err
        callback(err)
    )

  transformTemplate:(template)->
    if template not instanceof ChannelTemplate
      throw new Error('template must be type of ChannelTemplate and transformTemplate wasn\'t used')
    return template



  sendMessage:(message,destination,callback)->
    return callback(new Error('sendMessage not implemented'))

  validateDestination:(destination)->
    if not destination
      throw new Error(util.format(destination) + ' is not a valid destination')
    return yes
  validateTemplate:(template)->
    return yes

  debug:()->
    if @options.debug
      console.log.apply(console,arguments)

NotificatorChannel.ChannelTemplate = ChannelTemplate
NotificatorChannel.Destination = Destination


module.exports = NotificatorChannel