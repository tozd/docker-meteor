var mongodb = require('mongodb');
var waitingFor = 2;
function tryConnect(url) {
	mongodb.MongoClient.connect(url, {
		connectTimeoutMS: 5000,
		socketTimeoutMS: 5000
	}, function (error, db) {
		if (error === null) {
			const localDb = db.db('local');
			const admin = localDb.admin();

			// Ping the server
			admin.ping(function (err, result) {
				if (error === null) {
					if (--waitingFor <= 0) {
						process.exit(0);
					}
					return;
				}
				else {
					console.error("Waiting for database", error);
				}
				setTimeout(function () { tryConnect(url) }, 100);
			});
			return;
		}
		else {
			console.error("Waiting for database", error);
		}
		setTimeout(function () { tryConnect(url) }, 100);
	});
}
tryConnect(process.env.MONGO_URL);
