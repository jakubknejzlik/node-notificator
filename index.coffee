module.exports = require('./lib/Notificator')

module.exports.Channel = require('./lib/NotificatorChannel')
module.exports.EmailChannel = require('./lib/channels/EmailChannel')
module.exports.APNSChannel = require('./lib/channels/APNSChannel')