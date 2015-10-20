// Generated by CoffeeScript 1.10.0
(function() {
  var Notificator, assert, defaultEmailTemplate, emailChannel, emailDestinations, emailTemplates;

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
    text: 'default email body {{receiver}}',
    html: 'default email HTML body {{receiver}}'
  };

  emailDestinations = {
    'test': 'jakub.knej@gmail.com'
  };

  emailChannel = new Notificator.EmailChannel({
    getDestinations: function(receiver, callback) {
      return callback(null, [emailDestinations[receiver]]);
    },
    getTemplate: function(event, language, callback) {
      console.log(event, language);
      return callback(null, emailTemplates[event]);
    },
    defaultTemplate: defaultEmailTemplate,
    service: 'MailGun',
    auth: {
      user: 'postmaster@sandbox8a06541ad48441929ac3c146e6a13dd2.mailgun.org',
      pass: '...'
    }
  });

  describe('Notificator', function() {
    var notificator;
    notificator = new Notificator();
    notificator.registerEvent('test');
    notificator.addChannel('mail', emailChannel);
    it('should have one channel', function() {
      return assert.equal(notificator.channels.length, 1);
    });
    it('should find template', function(done) {
      var channel;
      channel = notificator.channels[0].channel;
      assert.ok(channel);
      return notificator.getTemplate('test', channel, 'en', function(err, template) {
        assert.ifError(err);
        assert.deepEqual(template, emailTemplates['test']);
        return done();
      });
    });
    it('should return default template if not found', function(done) {
      var channel;
      channel = notificator.channels[0].channel;
      assert.ok(channel);
      return notificator.getTemplate('blah', channel, 'en', function(err, template) {
        assert.ifError(err);
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
        assert.equal(destinations[0], emailDestinations['test']);
        return done();
      });
    });
    it('should fail to accept invalid destination for channel', function(done) {
      var channel;
      channel = notificator.channels[0].channel;
      assert.ok(channel);
      return channel.getDestinations('invalid receiver', function(err, destinations) {
        assert.equal(err.message, 'undefined is not valid email');
        return done();
      });
    });
    it('should parse template', function(done) {
      var channel;
      channel = notificator.channels[0].channel;
      assert.ok(channel);
      return notificator.getTemplate('blah', channel, 'en', function(err, template) {
        var parsedTemplate;
        assert.ifError(err);
        assert.ok(template);
        parsedTemplate = notificator.parseTemplate(template, 'test@example.com', {
          sender: 'sender@example.com'
        });
        assert.equal(parsedTemplate.subject, 'default subject test@example.com');
        assert.equal(parsedTemplate.text, 'default email body test@example.com');
        assert.equal(parsedTemplate.html, 'default email HTML body test@example.com');
        return done();
      });
    });
    it('should not sent unknown notification', function(done) {
      return notificator.notify('blahevent', 'test', function(err) {
        assert.equal(err.message, 'unknown event blahevent');
        return done();
      });
    });
    return it('should send notification', function(done) {
      return notificator.notify('test', 'test', done);
    });
  });

}).call(this);
