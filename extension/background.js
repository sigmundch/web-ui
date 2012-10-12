// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Glue code that interacts with dwc_compiler.dart to proxy arbitrary content
// for urls.


var existingRuleIds = {};
var onParse = null;

// TODO(jacobr): set the onParse property directly from Dart.
function setOnParseCallback(cb) {
  onParse = cb;
}

function proxyUrls(port, requests) {
  // Unfortunately we have to create the data urls from the content script due
  // to chrome security restrictions.
  port.postMessage({type: 'CREATE_DATA_URLS', requests: requests});
}

function onProxyUrls(requests) {
  var rulesToAdd = [];
  var ruleIdsToRemove = [];
  for (var i = 0; i < requests.length; i++) {
    var request = requests[i];
    var url = request.url;
    var redirectUrl = request.redirectUrl;
    var rule = {
      conditions: [
        new chrome.declarativeWebRequest.RequestMatcher(
            {url: {urlEquals: url}})
      ],
      actions: [
        new chrome.declarativeWebRequest.RedirectRequest(
          {redirectUrl: redirectUrl})
      ]};
    if (existingRuleIds[url]) {
      ruleIdsToRemove.push(existingRuleIds[url]);
    }
    rulesToAdd.push(rule);
  }

  if (ruleIdsToRemove.length > 0) {
    chrome.declarativeWebRequest.onRequest.removeRules(ruleIdsToRemove);
  }
  chrome.declarativeWebRequest.onRequest.addRules(rulesToAdd, function(added) {
    for(var i = 0; i < added.length; i++) {
      var r = added[i];
      existingRuleIds[r.conditions[0].url.urlEquals] = r.id;
    }
    // TODO(jacobr): notify caller that the proxy server is ready to use.
  })
}
chrome.extension.onConnect.addListener(function(port) {
  if (port.name == "parse") {
    // Listen to requests from chrome tabs to parse templates.
    port.onMessage.addListener(function(msg) {
      onParse(port, msg.url);
    });
  } else if (port.name == "proxy") {
    // Listen for requests to proxy urls.
    port.onMessage.addListener(function(msg) {
      onProxyUrls(msg.requests);
    });
  }
});
