# Notificator

[![Build Status](https://travis-ci.org/jakubknejzlik/node-notificator.svg)](https://travis-ci.org/jakubknejzlik/node-notificator)


Create notificator, specify channels and their logic of what, when and who send messages to (e-mail,apns, gcm). All in one place...and in your code use just notificator.notify('event',receiver,data).


# Example

```
Notificator = require('../index')


notificator = new Notificator({
    logging: false, // log messages
    dummy: false // don't send notifications (used for tests)
})

notificator.registerEvent('test') // you can specify wich events are valid


// create your channels

var messageData = {key:'value'}

// use your own model logic, this object is sent to getDestinations method as receiver (you can use for example sequelize object).
// also accepts array of receivers
var receiver = {};
notificator.notify('test',receiver,messageData,{channels:['gcm']})
    .then(done)
    .catch(done)

// or to notify directly
var destination = 'john.doe@example.com'; // also accepts array
notificator.notifyDestination('test','email',destination,messageData)
    .then(done)
    .catch(done)

```

### Email Channel
```
var emailChannel = new Notificator.EmailChannel({
  getDestinations:function(receiver, language, callback){
    callback(null,[{destination:receiver.email}]) // suppose we have (for example sequelize) user with email attribute
  }
  getTemplates:function(info,callback){
    var template = {
      subject:'default subject {{receiver}}',
      text:'default email body {{receiver}} {{JSON.stringify(_data)}}',
      html:'default email HTML body {{receiver}}'
    }
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
        callback(null,[{destination:device.token,language:device.language}]);
    }).catch(callback)
  }
  getTemplates:function(info,callback){
    template = {alert:'{{value}} notification test' + info.event + '_' + info.language,badge:'{{value+1}}'}
    callback(null,template)
  },
  feedbackHandler:function(items){
    items.forEach(function(item){
        console.log('disable destination:',item.destination,'disabled since:',item.date)
    })
  }
  feedbackInterval: 600,
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
  getTemplates:function(info,callback){
    template = new Notificator.GCMChannel.Template({
      data:{
        title:'{{value}}' + info.event + '_' + info.language,
        message:'{{value}} body'
      }
    })
    callback(null,template)
  },
  apiKey:'...'
})

notificator.addChannel('gcm',gcmChannel)
```
