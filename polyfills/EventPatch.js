/**
 * React Native 0.76+ sets Event phase constants (NONE, CAPTURING_PHASE,
 * AT_TARGET, BUBBLING_PHASE) as non-writable, non-configurable data properties
 * on both Event and Event.prototype via Object.defineProperty WITHOUT specifying
 * writable (so it defaults to false). Compiled class field initializers then try
 * `this.NONE = undefined` in strict mode and throw.
 *
 * Fix: intercept Object.defineProperty before the base polyfills run. When a
 * phase constant is being registered as a non-writable data property, replace
 * it with an accessor: getter returns the constant value, setter is a no-op
 * that silently absorbs class field assignments without creating an own property.
 */
(function () {
  var PHASE_CONSTANTS = ['NONE', 'CAPTURING_PHASE', 'AT_TARGET', 'BUBBLING_PHASE'];
  var _defineProperty = Object.defineProperty;

  Object.defineProperty = function (obj, prop, descriptor) {
    try {
      if (
        PHASE_CONSTANTS.indexOf(prop) !== -1 &&
        descriptor != null &&
        'value' in descriptor &&
        !descriptor.writable // catches both explicit false and omitted (undefined)
      ) {
        var val = descriptor.value;
        return _defineProperty(obj, prop, {
          get: function () { return val; },
          set: function () { /* no-op: absorbs class field init */ },
          enumerable: descriptor.enumerable !== false,
          configurable: true,
        });
      }
    } catch (e) {}
    return _defineProperty(obj, prop, descriptor);
  };
})();
