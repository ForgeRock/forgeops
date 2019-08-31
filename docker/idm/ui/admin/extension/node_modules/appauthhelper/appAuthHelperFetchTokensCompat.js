window.Promise = window.Promise || (typeof require("promise-polyfill") === "function" ? require("promise-polyfill") : require("promise-polyfill").default);
window.fetch = window.fetch || require("whatwg-fetch").fetch;
require("url-polyfill");
require("webcrypto-shim");
String.prototype.includes = String.prototype.includes || (function (substr) { return this.indexOf(substr) !== -1; });

require("./appAuthHelperFetchTokens");
