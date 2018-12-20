var mongodb = require('mongodb');

var waitingFor = 2;

function tryConnect(url) {
  mongodb.MongoClient.connect(url, {
    useNewUrlParser: true,
    socketTimeoutMS: 5000,
    connectTimeoutMS: 5000
    }, function (error, db) {
    if (error === null) {
      db.db(db.s.options.db).command({ping: 1}, function(error, result) {
        if (error === null) {
          if (--waitingFor <= 0) {
            process.exit(0);
          }
          return;
        }
        else {
          console.error("Waiting for database", error);
        }

        setTimeout(function() { tryConnect(url) }, 100);
      });
      return;
    }
    else {
      console.error("Waiting for database", error);
    }

    setTimeout(function() { tryConnect(url) }, 100);
  });
}

tryConnect(process.env.MONGO_URL);
tryConnect(process.env.MONGO_OPLOG_URL);
