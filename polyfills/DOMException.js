/* Polyfill DOMException for Hermes runtimes that don't expose it natively. */
if (typeof DOMException === 'undefined') {
  var DOMException = function DOMException(message, name) {
    this.message = message || '';
    this.name = name || 'Error';
    var err = new Error(message);
    this.stack = err.stack;
  };
  DOMException.prototype = Object.create(Error.prototype);
  DOMException.prototype.constructor = DOMException;
  global.DOMException = DOMException;
}
