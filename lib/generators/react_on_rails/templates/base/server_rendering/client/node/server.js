/**
 * Created by Alexey Karasev on 11/04/16.
 */


var net = require('net');
var fs = require('fs');

//fs.watch('../../app/assets/webpack/server-bundle.js', (event, filename) => {

var bundlePath = "../../app/assets/webpack";

if (!fs.existsSync(bundlePath)){
    fs.mkdirSync(bundlePath);
}

fs.watch(bundlePath, (event, filename) => {
    if (filename === "server-bundle.js") {
        require(bundlePath + "/server-bundle.js");
    }
});

// This server listens on a Unix socket at /var/run/mysocket
var unixServer = net.createServer(function (connection) {
    connection.setEncoding('utf8');
    connection.on('data', (data)=> {
        var result = eval(data);
        connection.write(result);
    });
});
unixServer.listen('node.sock');

process.on('SIGINT', () => {
    unixServer.close();
    process.exit();
});
