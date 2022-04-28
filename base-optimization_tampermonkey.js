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

addStyleString(`*{ font-variant-ligatures: normal !important }`);

})();