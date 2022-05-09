// ==UserScript==
// @name        Zerohazard's Font Script - Lite
// @namespace   Violentmonkey Scripts
// @match       *://*/*
// @grant       none
// @author      Zerohazard
// @match        http://*/*
// @match        https://*/*
// @match        http://*
// @match        https://*
// @match        *
// ==/UserScript==

(function() {
  'use strict';

  function addStyleString(str) {
    var node = document.createElement('style');
    node.innerHTML = str;
    document.body.appendChild(node);
  }
  addStyleString(`* { font-variant-ligatures: normal !important }`);
  addStyleString(`* { font-variant-numeric: lining-nums !important; font-feature-settings: "lnum" !important; }`);

})();
