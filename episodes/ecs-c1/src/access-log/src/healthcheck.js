var http = require("http");

var options = {
    host : "localhost",
    port : "80",
    path : "/healthz",
    timeout : 300
};

var request = http.request(options, (res) => {
    console.log(`STATUS: ${res.statusCode}`);
    if (res.statusCode == 200) {
        process.exit(0);
    }
    else {
        process.exit(1);
    }
});

request.on('error', function(err) {
    console.log('ERROR');
    process.exit(1);
});

request.end();