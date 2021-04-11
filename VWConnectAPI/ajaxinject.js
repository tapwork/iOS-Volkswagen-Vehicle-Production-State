var open = XMLHttpRequest.prototype.open;
XMLHttpRequest.prototype.open = function() {
    this.addEventListener("load", function() {
        var message = {"status" : this.status, "responseURL" : this.responseURL, "responseText" : this.responseText}
        webkit.messageHandlers.handler.postMessage(message);
    });
    open.apply(this, arguments);
};
