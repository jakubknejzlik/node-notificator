gcm = require('node-gcm')

NotificatorChannel = require('../NotificatorChannel')

class GCMTemplate extends NotificatorChannel.ChannelTemplate
  constructor:(payload)->
    for key,value of payload
      @[key] = value


class GCMChannel extends NotificatorChannel
  constructor:(options)->
    @sender = new gcm.Sender(options.apiKey)
    super(options)

  sendMessage:(message,destination,callback)->
    message = new gcm.Message(message)
    @sender.sendNoRetry(message,{registrationIds:[destination.destination]},(errCode,result)->
      if errCode
        return callback(new Error('unexpected error with status code: ' + errCode))
      callback(null,result)
    )

  validateTemplate:(template)->
    super(template)

  validateDestination:(destination)->
    return yes


GCMChannel.Template = GCMTemplate

module.exports = GCMChannel