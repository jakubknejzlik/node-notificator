fs = require('fs')
assert = require('assert')

Notificator = require('../index')


emailTemplates = {
  'test':new Notificator.EmailChannel.Template('email subject','email body','email HTML body')
}

defaultEmailTemplate = new Notificator.EmailChannel.Template(
  'default subject {{receiver}}',
  'default email body {{receiver}} {{JSON.stringify(_data)}}',
  'default email HTML body {{receiver}}'
)

emailDestinations = {
  'test':'jakub.knejzlik@gmail.com'
}
apnsDestinations = {
  'test':'d1ed7c9829ab244e52645e18008f49867bcd1fa04a4913274d5a23071d5af3d8'
}
gcmDestinations = {
  'test':'dNUcjs0FMK0:APA91bEtyrRYwNGawBNNrD7TmchAVxMoeylDQiKViS74IvD5GPMo9U4RLC3EBHtoXY6aJFjW22aFg0rmrchlWil06sQQ_m8yAVMcM5ZwhQvUWuBVvA14fWmSOUlPu25uBNFVrYzCzb30'
}

emailChannel = new Notificator.EmailChannel({
  getDestinations:(receiver,callback)->
    callback(null,[new Notificator.EmailChannel.Destination(emailDestinations[receiver],'en')])
  getTemplates:(event,language,callback)->
    console.log(event,language)
    callback(null,[emailTemplates[event]])
  defaultTemplate:defaultEmailTemplate
  service: 'MailGun',
  auth: {
    user: 'no-reply@...',
    pass: ''
  }
})

apnsChannel = new Notificator.APNSChannel({
  getDestinations:(receiver,callback)->
    callback(null,[apnsDestinations[receiver]])
  getTemplates:(event,language,callback)->
    template = new Notificator.APNSChannel.Template('{{value}} notification test' + event + '_' + language,'{{value+1}}')
    callback(null,[template])
#  cert:fs.readFileSync(__dirname + '/apns-cert.pem')
#  key:fs.readFileSync(__dirname + '/apns-key.pem')
  passphrase:'blah'
  production:yes
})

gcmChannel = new Notificator.GCMChannel({
  getDestinations:(receiver,callback)->
    callback(null,[gcmDestinations[receiver]])
  getTemplates:(event,language,callback)->
    template = new Notificator.GCMChannel.Template({
      data:{
        title:'{{value}}' + event + '_' + language,
        message:'{{value}} body'
      }
    })
    callback(null,template)
  apiKey:'...'
})

describe('Notificator',()->
  notificator = new Notificator()

  notificator.registerEvent('test')

  notificator.addChannel('email',emailChannel)
  notificator.addChannel('apns',apnsChannel)
  notificator.addChannel('gcm',gcmChannel)

#  it.only('should send push notification',(done)->
#    @timeout(5000)
#    myDevice = new apn.Device('d1ed7c9829ab244e52645e18008f49867bcd1fa04a4913274d5a23071d5af3d8');
#
#    note = new apn.Notification();
#
#    note.badge = 2;
#    note.alert = "asfadf"
#
#    conn.pushNotification(note, myDevice);
#  )

  it('should have number of channels',()->
    assert.equal(notificator.channels.length,3)
  )

  it('should find template',(done)->
    channel = notificator.channels[0].channel
    assert.ok(channel)
    notificator.getTemplates('test',channel,'en',(err,templates)->
      assert.ifError(err)
      assert.equal(templates.length,1)
      template = templates[0]
      assert.deepEqual(template,emailTemplates['test'])
      assert.ok(template instanceof Notificator.Channel.ChannelTemplate)
      done()
    )
  )

  it('should return default template if not found',(done)->
    channel = notificator.channels[0].channel
    assert.ok(channel)
    notificator.getTemplates('blah',channel,'en',(err,templates)->
      assert.ifError(err)
      assert.equal(templates.length,1)
      template = templates[0]
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
      assert.equal(destinations[0].destination,emailDestinations['test'])
      assert.equal(destinations[0].language,'en')
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
    notificator.getTemplates('blah',channel,'en',(err,templates)->
      assert.ifError(err)
      assert.ok(templates)
      assert.equal(templates.length,1)
      template = templates[0]
      parsedTemplate = notificator.getMessageFromTemplate(template,'test@example.com',{sender:'sender@example.com'})
      assert.equal(parsedTemplate.subject,'default subject test@example.com')
      assert.equal(parsedTemplate.text,"default email body test@example.com {\"receiver\":\"test@example.com\",\"destination\":{\"sender\":\"sender@example.com\"}}")
      assert.equal(parsedTemplate.html,'default email HTML body test@example.com')
      done()
    )
  )

  it('should not sent unknown notification',(done)->
    notificator.notify('blahevent','test').catch((err)->
      assert.equal(err.message,'unknown event blahevent')
      done()
    )
  )

#  it.only('should send notification',(done)->
#    @timeout(5000)
#    notificator.notify('test','test',{value:970},{channels:['gcm']}).then(done).catch(done)
#  )
)