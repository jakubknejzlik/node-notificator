apn = require('apn')
async = require('async')
extend = require('extend')

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

    feedbackOptions = extend(options,{
      production:options.production,
      batchFeedback: yes,
      interval: options.feedbackInterval or 600
    })

    if options.feedbackHandler
      @feedback = new apn.feedback(feedbackOptions)
      @feedback.on('feedback',(feedbacks)->
        items = []
        for item in feedbacks
          items.push({
            destination:item.device.toString(),
            date: new Date(item.time)
          })
        options.feedbackHandler(items)
      )

    super(options)

  sendMessage:(message,destination,callback)->
    device = new apn.Device(destination.destination)
    @connection.pushNotification(message,device)
    async.nextTick(()->
      callback() if callback
    )

  validateTemplate:(template)->
    if not template.alert and not template.payload and not template.sound and not template.badge
      throw new Error('apns template must have at least one attribute (available attributes alert, badge, sound, payload)')
    return super(template)

  validateDestination:(destination)->
    return yes

  transformTemplate:(template)->
    return new APNSTemplate(template.alert,template.badge,template.sound,template.payload)

  wrappedDestination:(destination)->
    if destination?.token
      destination.destination = destination.token
      delete destination.token
    return super(destination)



APNSChannel.Template = APNSTemplate

module.exports = APNSChannel