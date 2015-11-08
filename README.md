# Notificator

[![Build Status](https://travis-ci.org/jakubknejzlik/node-notificator.svg)](https://travis-ci.org/jakubknejzlik/node-notificator)


Create notificator, specify channels and their logic of what, when and who send messages to (e-mail,apns, gcm). All in one place...and in your code use just notificator.notify('event',receiver,data).


# Example

```
Notificator = require('../index')


notificator = new Notificator()

notificator.registerEvent('test') // you can specify wich events are valid


// create your channels

var messageData = {key:'value'}

var receiver = {}; // use your own model logic, this object is sent to getDestinations method as receiver (you can use for example sequelize object).
notificator.notify('test',receiver,messageData,{channels:['gcm']})
    .then(done)
    .catch(done)

```

### Email Channel
```
var emailChannel = new Notificator.EmailChannel({
  getDestinations:function(receiver, language, callback){
    callback(null,[new Notificator.EmailChannel.Destination(receiver.email)]) // suppose we have (for example sequelize) user with email attribute
  }
  getTemplates:function(event,language,callback){
    var template = new Notificator.EmailChannel.Template(
      'default subject {{receiver}}',
      'default email body {{receiver}} {{JSON.stringify(_data)}}',
      'default email HTML body {{receiver}}'
    )
    callback(null,[template])
  }
//  defaultTemplate:defaultEmailTemplate,
  service: 'MailGun',
  auth: {
    user: 'no-reply@...',
    pass: ''
  }
})

notificator.addChannel('email',emailChannel)
```

### APNS Channel

```
var apnsChannel = new Notificator.APNSChannel({
  getDestinations:function(receiver, language, callback){
    receiver.getApnsDevice().then(function(device){ // suppose we have (for example sequelize) user object with apnsDevice
        callback(null,[new Notificator.APNSChannel.Destination(device.token,device.language)]);
    }).catch(callback)
  }
  getTemplates:function(event,language,callback){
    template = new Notificator.APNSChannel.Template('{{value}} notification test' + event + '_' + language,'{{value+1}}')
    callback(null,template)
  }
  cert:fs.readFileSync(__dirname + '/apns-cert.pem'),
  key:fs.readFileSync(__dirname + '/apns-key.pem'),
  passphrase:'blah',
  production:true
})

notificator.addChannel('apns',apnsChannel)
```

### GCM Channel

```
var gcmChannel = new Notificator.GCMChannel({
  getDestinations:function(receiver, language, callback){
    receiver.getGcmDevice().then(function(device){ // suppose we have (for example sequelize) user object with gcmDevice
      callback(null,[new Notificator.GCMChannel.Destination(device.token,device.language)]);
    }).catch(callback)
  },
  getTemplates:function(event,language,callback){
    template = new Notificator.GCMChannel.Template({
      data:{
        title:'{{value}}' + event + '_' + language,
        message:'{{value}} body'
      }
    })
    callback(null,template)
  },
  apiKey:'...'
})

notificator.addChannel('gcm',gcmChannel)
```
