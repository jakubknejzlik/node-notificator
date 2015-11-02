apn = require('apn')
async = require('async')

NotificatorChannel = require('../NotificatorChannel')

class APNSTemplate extends NotificatorChannel.ChannelTemplate
  constructor:(@alert,@badge,@sound,@payload)->

  getMessage:(data)->
    data = super(data)
    notification = new apn.Notification()
    for key of data
      if data[key]
        notification[key] = data[key]
    if data.badge
      notification.badge = parseInt(data.badge)
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