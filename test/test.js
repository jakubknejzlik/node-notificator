// Generated by CoffeeScript 1.10.0
(function() {
  var Notificator, apnsChannel, apnsDestinations, assert, defaultEmailTemplate, emailChannel, emailDestinations, emailTemplates, fs, gcmChannel, gcmDestinations;

  fs = require('fs');

  assert = require('assert');

  Notificator = require('../index');

  emailTemplates = {
    'test': {
      subject: 'email subject',
      text: 'email body',
      html: 'email HTML body'
    }
  };

  defaultEmailTemplate = {
    subject: 'default subject {{receiver}}',
    text: 'default email body {{receiver}} {{JSON.stringify(_data)}}',
    html: 'default email HTML body {{receiver}}'
  };

  emailDestinations = {
    'test': {
      email: 'jakub.knejzlik@gmail.com',
      lang: 'en'
    }
  };

  apnsDestinations = {
    'test': 'd1ed7c9829ab244e52645e18008f49867bcd1fa04a4913274d5a23071d5af3d8'
  };

  gcmDestinations = {
    'test': 'dNUcjs0FMK0:APA91bEtyrRYwNGawBNNrD7TmchAVxMoeylDQiKViS74IvD5GPMo9U4RLC3EBHtoXY6aJFjW22aFg0rmrchlWil06sQQ_m8yAVMcM5ZwhQvUWuBVvA14fWmSOUlPu25uBNFVrYzCzb30'
  };

  emailChannel = new Notificator.EmailChannel({
    getDestinations: function(receiver, callback) {
      return callback(null, [emailDestinations[receiver]]);
    },
    getTemplates: function(info, callback) {
      return callback(null, [emailTemplates[info.event]]);
    },
    defaultTemplate: defaultEmailTemplate,
    service: 'MailGun',
    auth: {
      user: 'postmaster@...',
      pass: ''
    }
  });

  apnsChannel = new Notificator.APNSChannel({
    getDestinations: function(receiver, callback) {
      return callback(null, [
        apnsDestinations[receiver], {
          token: apnsDestinations[receiver]
        }
      ]);
    },
    getTemplates: function(info, callback) {
      var template;
      template = {
        alert: '{{value}} notification test' + info.event + '_' + info.language,
        '{{value+1}}': '{{value+1}}'
      };
      return callback(null, [template]);
    },
    feedbackInterval: 600,
    passphrase: 'blah',
    production: true
  });

  gcmChannel = new Notificator.GCMChannel({
    getDestinations: function(receiver, callback) {
      return callback(null, [gcmDestinations[receiver]]);
    },
    getTemplates: function(info, callback) {
      var template;
      template = new Notificator.GCMChannel.Template({
        data: {
          title: '{{value}}' + info.event + '_' + info.language,
          message: '{{value}} body'
        }
      });
      return callback(null, template);
    },
    apiKey: '...'
  });

  describe('Notificator', function() {
    var notificator;
    notificator = new Notificator({
      dummy: true,
      logging: true
    });
    notificator.registerEvent('test');
    notificator.addChannel('email', emailChannel);
    notificator.addChannel('apns', apnsChannel);
    notificator.addChannel('gcm', gcmChannel);
    it('should have number of channels', function() {
      return assert.equal(notificator.channels.length, 3);
    });
    it('should find template', function(done) {
      var channel;
      channel = notificator.channels[0].channel;
      assert.ok(channel);
      return notificator.getTemplates(channel, {
        event: 'test',
        language: 'en',
        data: null
      }, function(err, templates) {
        var template;
        assert.ifError(err);
        assert.equal(templates.length, 1);
        template = templates[0];
        assert.deepEqual(template, emailTemplates['test']);
        assert.ok(template instanceof Notificator.Channel.ChannelTemplate);
        return done();
      });
    });
    it('should get message from template', function() {
      var message, template;
      template = new Notificator.EmailChannel.Template('subject:{{subject}}', 'text:{{text}}', 'html:{{html}}');
      message = template.getMessage({
        subject: 'subj',
        text: 'txt',
        html: 'HTML'
      });
      assert.equal(message.subject, 'subject:subj');
      assert.equal(message.text, 'text:txt');
      assert.equal(message.html, 'html:HTML');
      template = new Notificator.EmailChannel.Template(null, null, null);
      message = template.getMessage({
        subject: 'subj',
        text: 'txt',
        html: 'HTML'
      });
      assert.equal(message.subject, null);
      assert.equal(message.text, null);
      return assert.equal(message.html, null);
    });
    it('should return default template if not found', function(done) {
      var channel;
      channel = notificator.channels[0].channel;
      assert.ok(channel);
      return notificator.getTemplates(channel, {
        event: 'blah',
        language: 'en',
        data: null
      }, function(err, templates) {
        var template;
        assert.ifError(err);
        assert.equal(templates.length, 1);
        template = templates[0];
        assert.deepEqual(template, defaultEmailTemplate);
        return done();
      });
    });
    it('should return destinations for channel', function(done) {
      var channel;
      channel = notificator.channels[0].channel;
      assert.ok(channel);
      return channel.getDestinations('test', function(err, destinations) {
        assert.ifError(err);
        assert.equal(destinations.length, 1);
        assert.equal(destinations[0].destination, emailDestinations['test'].email);
        assert.equal(destinations[0].language, 'en');
        return done();
      });
    });
    it('should fail to accept invalid destination for channel', function(done) {
      var channel;
      channel = notificator.channels[0].channel;
      assert.ok(channel);
      return channel.getDestinations('invalid receiver', function(err, destinations) {
        assert.equal(err.message, 'undefined is not a valid destination');
        return done();
      });
    });
    it('should parse template', function(done) {
      var channel;
      channel = notificator.channels[0].channel;
      assert.ok(channel);
      return notificator.getTemplates(channel, {
        event: 'blah',
        language: 'en',
        data: null
      }, function(err, templates) {
        var parsedTemplate, template;
        assert.ifError(err);
        assert.ok(templates);
        assert.equal(templates.length, 1);
        template = templates[0];
        parsedTemplate = notificator.getMessageFromTemplate(template, 'test@example.com', {
          sender: 'sender@example.com'
        });
        assert.equal(parsedTemplate.subject, 'default subject test@example.com');
        assert.equal(parsedTemplate.text, "default email body test@example.com {\"receiver\":\"test@example.com\",\"destination\":{\"sender\":\"sender@example.com\"}}");
        assert.equal(parsedTemplate.html, 'default email HTML body test@example.com');
        return done();
      });
    });
    it('should not sent unknown notification', function(done) {
      return notificator.notify('blahevent', 'test')["catch"](function(err) {
        assert.equal(err.message, 'unknown event blahevent');
        return done();
      });
    });
    it('should send notification', function(done) {
      this.timeout(5000);
      return notificator.notify('test', 'test', {
        value: 970
      }, {
        __channels: ['email']
      }).then(done)["catch"](done);
    });
    return it('should send direct notification', function(done) {
      this.timeout(5000);
      return notificator.notifyDestination('test', 'email', 'jakub.knejzlik@gmail.com', {
        value: 970
      }).then(done)["catch"](done);
    });
  });

}).call(this);
