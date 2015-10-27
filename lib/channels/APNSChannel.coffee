apn = require('apn')
async = require('async')

NotificatorChannel = require('../NotificatorChannel')

class APNSTemplate extends NotificatorChannel.ChannelTemplate
  constructor:()->

  getMessage:(data)->
    data = super(data)
    notification = new apn.Notification()
    for key of data
      notification[key] = data[key]
    return notification


class APNSChannel extends NotificatorChannel
  constructor:(options)->
    @connection = new apn.Connection(options)
    @connection.on('error',console.error)
    super(options)

  sendMessage:(message,destination,callback)->
    device = new apn.Device(destination)
    @connection.pushNotification(message,device)
    async.nextTick(()->
      callback() if callback
    )

  validateTemplate:(template)->
    super(template)

  validateDestination:(destination)->
    return yes


APNSChannel.Template = APNSTemplate

module.exports = APNSChannel