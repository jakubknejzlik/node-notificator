nodemailer = require('nodemailer')
validator = require('validator')

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
    if @options.sender and not validator.isEmail(@options.sender)
      return callback(new Error('you must specify valid email in options.sender'))
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
      throw new Error(destination.destination + ' is not valid email')
    return yes


EmailChannel.Template = EmailTemplate

module.exports = EmailChannel