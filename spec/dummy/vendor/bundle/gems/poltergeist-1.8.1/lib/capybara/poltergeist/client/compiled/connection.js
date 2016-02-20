var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

Poltergeist.Connection = (function() {
  function Connection(owner, port) {
    this.owner = owner;
    this.port = port;
    this.commandReceived = bind(this.commandReceived, this);
    this.socket = new WebSocket("ws://127.0.0.1:" + this.port + "/");
    this.socket.onmessage = this.commandReceived;
    this.socket.onclose = function() {
      return phantom.exit();
    };
  }

  Connection.prototype.commandReceived = function(message) {
    return this.owner.runCommand(JSON.parse(message.data));
  };

  Connection.prototype.send = function(message) {
    return this.socket.send(JSON.stringify(message));
  };

  return Connection;

})();
