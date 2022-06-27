// ==UserScript==
// @name        Zerohazard's Font Script
// @author      twitter @Zerohazard8x
// ==/UserScript==

(function () {
  "use strict";

  function addStyleString(str) {
    var node = document.createElement("style");
    node.innerHTML = str;
    document.body.appendChild(node);
  }
  addStyleString(
    `* { font-variant-ligatures: common-ligatures, contextual !important }`
  );
  addStyleString(
    `* { font-variant-numeric: lining-nums, tabular-nums !important }`
  );
  addStyleString(
    `* { font-feature-settings: "kern", "liga", "clig", "calt", "lnum", "tnum" !important }`
  );
  addStyleString(`* { font-kerning: normal !important }`);
})();
