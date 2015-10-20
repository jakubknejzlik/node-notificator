nodemailer = require('nodemailer')
validator = require('validator')

NotificatorChannel = require('../NotificatorChannel')

class EmailChannel extends NotificatorChannel
  constructor:(options)->
    super(options)

  getTransport:()->
    if not @transport
      @transport = nodemailer.createTransport(@options)
    return @transport

  sendMessage:(message,destination,callback)->
    messageOptions = {
      from: message.from or @options.from or 'sender not specified'
      to: destination
      subject: message.subject or 'subject not specified'
      text: message.text or 'text not specified'
      html: message.html or 'html not specified'
    }

    @getTransport().sendMail(messageOptions,callback)

  validateDestination:(destination)->
    if not validator.isEmail(destination)
      throw new Error(destination + ' is not valid email')
    return yes


module.exports = EmailChannel