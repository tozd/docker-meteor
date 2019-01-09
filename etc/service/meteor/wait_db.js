var mongodb = require('mongodb');

var waitingFor = 2;

/**
 * Attempts to connect to mongodb instance and checks if database exists
 *
 */
function tryConnect(url) {

  // Responds to the ping command handling error and success, needs to be inside
  //  tryConnect as url parameter is required to retry
  var handlePing = function(error, result) {
    if (error === null) {
      if (--waitingFor <= 0) {
        process.exit(0);
      }
      return;
    }
    else {
      console.error("Waiting for database", error);
    }

    setTimeout(function() { tryConnect(url); }, 100);
  };

  var params = {
    options: {
      useNewUrlParser: true,
      socketTimeoutMS: 5000,
      connectTimeoutMS: 5000
    },
    ping: function(client) {
      return client.db(client.s.options.db).command({ping: 1}, handlePing);
    }
  };

  // Backwards compatible with MongoClient v2
  if (mongodb.MongoClient.define !== undefined) {
    params = {
      options: {
        server: {
          socketOptions: {
            connectTimeoutMS: 5000,
            socketTimeoutMS: 5000
          }
        }
      },
      ping: function(client) {
        return client.command({ping: 1}, handlePing);
      }
    };
  }

  // Connect to mongo instance
  mongodb.MongoClient.connect(url, params.options, function (error, client) {
    if (error === null) {
      params.ping(client);
      return;
    }
    else {
      console.error("Waiting for database", error);
    }

    setTimeout(function() { tryConnect(url); }, 100);
  });
}

tryConnect(process.env.MONGO_URL);
tryConnect(process.env.MONGO_OPLOG_URL);
