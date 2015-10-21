assert = require('assert')

Notificator = require('../index')


emailTemplates = {
  'test':new Notificator.EmailChannel.Template('email subject','email body','email HTML body')
}

defaultEmailTemplate = new Notificator.EmailChannel.Template(
  'default subject {{receiver}}',
  'default email body {{receiver}}',
  'default email HTML body {{receiver}}'
)

emailDestinations = {
  'test':'jakub.knej@gmail.com'
}

emailChannel = new Notificator.EmailChannel({
  getDestinations:(receiver,callback)->
    callback(null,[emailDestinations[receiver]])
  getTemplate:(event,language,callback)->
    console.log(event,language)
    callback(null,emailTemplates[event])
  defaultTemplate:defaultEmailTemplate
  service: 'MailGun',
  auth: {
    user: 'postmaster@sandbox8a06541ad48441929ac3c146e6a13dd2.mailgun.org',
    pass: '...'
  }
})

describe('Notificator',()->
  notificator = new Notificator()

  notificator.registerEvent('test')

  notificator.addChannel('mail',emailChannel)

  it('should have one channel',()->
    assert.equal(notificator.channels.length,1)
  )

  it('should find template',(done)->
    channel = notificator.channels[0].channel
    assert.ok(channel)
    notificator.getTemplate('test',channel,'en',(err,template)->
      assert.ifError(err)
      assert.deepEqual(template,emailTemplates['test'])
      done()
    )
  )

  it('should return default template if not found',(done)->
    channel = notificator.channels[0].channel
    assert.ok(channel)
    notificator.getTemplate('blah',channel,'en',(err,template)->
      assert.ifError(err)
      assert.deepEqual(template,defaultEmailTemplate)
      done()
    )
  )

  it('should return destinations for channel',(done)->
    channel = notificator.channels[0].channel
    assert.ok(channel)
    channel.getDestinations('test',(err,destinations)->
      assert.ifError(err)
      assert.equal(destinations.length,1)
      assert.equal(destinations[0],emailDestinations['test'])
      done()
    )
  )

  it('should fail to accept invalid destination for channel',(done)->
    channel = notificator.channels[0].channel
    assert.ok(channel)
    channel.getDestinations('invalid receiver',(err,destinations)->
      assert.equal(err.message,'undefined is not valid email')
      done()
    )
  )

  it('should parse template',(done)->
    channel = notificator.channels[0].channel
    assert.ok(channel)
    notificator.getTemplate('blah',channel,'en',(err,template)->
      assert.ifError(err)
      assert.ok(template)
      parsedTemplate = notificator.parseTemplate(template,'test@example.com',{sender:'sender@example.com'})
      assert.equal(parsedTemplate.subject,'default subject test@example.com')
      assert.equal(parsedTemplate.text,'default email body test@example.com')
      assert.equal(parsedTemplate.html,'default email HTML body test@example.com')
      done()
    )
  )

  it('should not sent unknown notification',(done)->
    notificator.notify('blahevent','test',(err)->
      assert.equal(err.message,'unknown event blahevent')
      done()
    )
  )

#  it('should send notification',(done)->
#    notificator.notify('test','test',done)
#  )
)