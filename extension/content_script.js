// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Glue code that runs on the page referencing dart web components.
// Some logic has to be placed here rather than on the background page
// because of chrome security restrictions.

// Port used to send requests to the background page to proxy urls.
var proxyPort = null;

// Port used to send requests to the background page to parse components.
var parsePort = null;

function endsWith(str, pattern) {
  return str.lastIndexOf(pattern) == str.length - pattern.length;
}

function onRequestParse() {
  if (parsePort == null) {
    parsePort = chrome.extension.connect({name: "parse"});
  }
  var l = window.location;
  var pageUrl = l.protocol + "//" + l.host + l.pathname;
  parsePort.postMessage({url: pageUrl});
  parsePort.onMessage.addListener(function(msg) {
    if (msg.type == "CREATE_DATA_URLS") {
      var requests = msg.requests;
      var response = [];
      for (var i = 0; i < requests.length; i++) {
        var request = requests[i];
        var url = request.url;
        var content = request.content;
        var contentType =
            endsWith(url, ".html") ? "text/html" : "application/javascript";
        var objectUrl = webkitURL.createObjectURL(
          new Blob([content], {type: contentType}));
        response.push({url: url, redirectUrl: objectUrl});
      }
      if (proxyPort == null) {
        proxyPort = chrome.extension.connect({name: "proxy"});
      }
      proxyPort.postMessage({requests: response});
      // TODO(jacobr): remove timeout and listen for a message from the
      // background page instead.
      var generatedPageUrl = pageUrl.replace(/[/]([^/]+)$/,
          function(match, p1) { return "/_" + p1 + ".html"});
      window.setTimeout(function() {
        for (var i = 0; i < requests.length; i++) {
          var request = requests[i];
          var url = request.url;
          var content = request.content;
          if (url == generatedPageUrl) {
            // Replace the contents of the existing document with the
            // proxied content at the url with an additional .html added.
            // We prefer this versus redirecting to the page with an extra
            // .html so that refreshing this page does the right thing.
            var newDoc = document.open("text/html", "replace");
            newDoc.write(content);
            newDoc.close();
          }
        }
      }, 100);
    }
  })

}

document.addEventListener("DOMContentLoaded", function() {
  if (document.querySelector("link[rel=components], element, template")) {
    // TODO(jacobr): should we always parse if there could be components?
    onRequestParse();
  }
});

window.addEventListener("message", function(event) {
  if (event.source != window)
    return;

  if (event.data.type == "PARSE") {
    onRequestParse();
  }
}, false);
