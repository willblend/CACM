// Copyright 2004 Google Inc.
// All Rights Reserved.
//
// A bunch of XML HTTP recipes used to do RPC from within javascript from
// Gagan Saksena's wiki page
// http://wiki.corp.google.com/twiki/bin/view/Main/JavaScriptRecipes

/** Candidate Active X types.
  * @private
  */
var _XH_ACTIVE_X_IDENTS = [
  "MSXML2.XMLHTTP.5.0", "MSXML2.XMLHTTP.4.0", "MSXML2.XMLHTTP.3.0",
  "MSXML2.XMLHTTP", "MICROSOFT.XMLHTTP.1.0", "MICROSOFT.XMLHTTP.1",
  "MICROSOFT.XMLHTTP" ];
/** The active x identifier used for ie.
 * @private
 */
var _xh_ieProgId = undefined;

// Domain for XmlHTTPRequest.readyState
var XML_READY_STATE_UNINITIALIZED  = 0;
var XML_READY_STATE_LOADING        = 1;
var XML_READY_STATE_LOADED         = 2;
var XML_READY_STATE_INTERACTIVE    = 3;
var XML_READY_STATE_COMPLETED      = 4;

/** initialize the private state used by other functions.
  * @private
  */
function _XH_XmlHttpInit() {
  // Nobody (on the web) is really sure which of the progid's listed is totally
  // necessary. It is known, for instance, that certain installations of IE will
  // not work with only Microsoft.XMLHTTP, as well as with MSXML2.XMLHTTP.
  // Safest course seems to be to do this -- include all known progids for
  // XmlHttp.
  if (typeof XMLHttpRequest == 'undefined' &&
      typeof ActiveXObject != 'undefined') {
    for (var i = 0; i < _XH_ACTIVE_X_IDENTS.length; i++) {
      var candidate = _XH_ACTIVE_X_IDENTS[i];

      try {
        new ActiveXObject(candidate);
        _xh_ieProgId = candidate;
        break;
      } catch (e) {
        // do nothing; try next choice
      }
    }

    // couldn't find any matches
    if (undefined === _xh_ieProgId) {
      throw ("Could not create ActiveXObject. ActiveX might be disabled, or " +
             "msxml might not be installed");
    }
  }
}

_XH_XmlHttpInit();

/** create and return an xml http request object that can be passed to
  * {@link #XH_XmlHttpGET} or {@link #XH_XmlHttpPOST}.
  */
function XH_XmlHttpCreate() {
  if (_xh_ieProgId !== undefined) {
    return new ActiveXObject(_xh_ieProgId);
  } else {
    return new XMLHttpRequest();
  }
}

/** send a get request.
  * @param xmlhttp as from {@link XH_XmlHttpCreate}.
  * @param url the service to contact
  * @param handler function called when the response is received.
  */
function XH_XmlHttpGET(xmlhttp, url, handler) {
  xmlhttp.onreadystatechange = handler;
  xmlhttp.open("GET", url, true);
  XH_XmlHttpSend(xmlhttp, null);
}

/** send a post request.
  * @param xmlhttp as from {@link XH_XmlHttpCreate}.
  * @param url the service to contact
  * @param data the request content.
  * @param handler function called when the response is received.
  */
function XH_XmlHttpPOST(xmlhttp, url, data, handler) {
  xmlhttp.onreadystatechange = handler;
  xmlhttp.open("POST", url, true);
  xmlhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  xmlhttp.setRequestHeader("Content-Length", data.length);
  XH_XmlHttpSend(xmlhttp, data);
}

function XH_XmlHttpOpen(xmlhttp, verb, url, handler) {
  xmlhttp.onreadystatechange = handler;
  xmlhttp.open(verb, url, true);
}

function XH_XmlHttpSetRequestHeader(xmlhttp, name, value) {
  xmlhttp.setRequestHeader(name, value);
}

function XH_XmlHttpSend(xmlhttp, data) {
  try {
    xmlhttp.send(data);
  } catch (e) {
    // you may want to log/debug this error
    // one that you should be aware of is e.number == -2146697208,
    // which occurs when the 'Languages...' setting in IE is empty.
    log('XMLHttpSend failed ' + e.toString() + '<br>' + e.stack);
    throw e;
  }
}

function XH_XmlHttpAbort(xmlhttp) {
  // IE crashes if you NULL out the onreadystatechange synchronously
  SafeTimeout(window, function() {
    xmlhttp.onreadystatechange = function() {};
  }, 0);
  if (xmlhttp.readyState < XML_READY_STATE_COMPLETED) {
    xmlhttp.abort();
  }
}
