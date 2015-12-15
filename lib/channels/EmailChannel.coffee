nodemailer = require('nodemailer')
validator = require('validator')
util = require('util')

NotificatorChannel = require('../NotificatorChannel')

class EmailTemplate extends NotificatorChannel.ChannelTemplate
  constructor:(@subject,@text,@html)->


class EmailChannel extends NotificatorChannel
  constructor:(options)->
    super(options)

  getTransport:()->
    if not @transport
      @transport = nodemailer.createTransport(@options)
    return @transport

  sendMessage:(message,destination,callback)->
    messageOptions = {
      from: @options.sender
      to: destination.destination
      subject: message.subject
      text: message.text
      html: message.html
    }
    @debug(messageOptions)
    @getTransport().sendMail(messageOptions,callback)

  validateTemplate:(template)->
    super(template)
    if template not instanceof EmailTemplate
      throw new Error('template must be type of EmailTemplate')
    if not template.subject
      throw new Error('email template must have subject')
    if not template.text and not template.html
      throw new Error('email template must have text or html')

  validateDestination:(destination)->
    super(destination)
    if not validator.isEmail(destination.destination)
      throw new Error(util.format(destination.destination) + ' is not valid email')
    return yes

  wrappedDestination:(destination)->
    if destination?.email
      destination.destination = destination.email
      delete destination.email
    return super(destination)


  transformTemplate:(template)->
    return new EmailTemplate(template.subject,template.text,template.html)

EmailChannel.Template = EmailTemplate

module.exports = EmailChannel