// ==UserScript==
// @name        Zerohazard's Font Script
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

  function ignoreerror() {
    return true
  }

  addStyleString(`* { font-variant-ligatures: normal !important }`);

  var a;
  var b = 0;

  var x;
  var y = 0;
  var regex = '/Andika|Lexend|Uniqlo|sst|YouTube|YT|speedee|Twitter|spotify|Samsung|Netflix|Amazon|CNN|adobe|intel|Reith|knowledge|abc|Yahoo|VICE|Google|GS Text|Android|bwi|Market|Razer|peacock|zilla|DDG|Bogle|tpu|ArtifaktElement|LG|GeForce|Sky|F1|Indy|Guardian|nyt|Times|Beaufort for LOL|MB|SF|Inter|Adelle|Barlow|Roboto|Avenir|Raleway|Proxima|Gotham|Futura|IBM|Clear Sans|Karla|Work Sans|Segoe|Selawik|WeblySleek|Commissioner|Oxygen|Myriad|Lucida|Lato|Nunito|Whitney|Motiva|Montserrat|PT|Fira|Ubuntu|Source|Noto|Open Sans|Droid Sans|Museo|DIN|Keiner|Kenyan Coffee|Oswald|Rubik|Industry|Rajdhani|Saira|Klavika|Chakra Petch|Univers|Franklin|Impact|Impacted|Poppins|Roobert|Circular|Manrope|Benton|Mark|Helvetica|Archivo|Sora|Interstate|Helmet|Arial|Arimo|Rodin|Hiragino|Yu|Gothic A1|Yantramanav|Komika|Bitter|Playfair|Lora|Linux|Shippori|artifakt|ヒラギノ角ゴ/'

  for (x != 1; y <= 1; y++) {
    window.onerror = ignoreerror();
    var font = window.getComputedStyle(document.getElementsByTagName('h1')[y]).getPropertyValue("font-family");
    if (`${regex}.test(font)`) {
      addStyleString(`* { font-family: ${font}, ${window.getComputedStyle(document.getElementsByTagName('i')[y]).getPropertyValue("font-family")} !important }`);
      addStyleString(`i { font-family: ${window.getComputedStyle(document.getElementsByTagName('i')[y]).getPropertyValue("font-family")} !important }`);
      x = 1;
    }
  }

  for (a != 1; b <= 1; b++) {
    window.onerror = ignoreerror();
    var font = window.getComputedStyle(document.getElementsByTagName('p')[b]).getPropertyValue("font-family");
    if (`${regex}.test(font)`) {
      addStyleString(`* { font-family: ${font}, ${window.getComputedStyle(document.getElementsByTagName('i')[b]).getPropertyValue("font-family")} !important }`);
      addStyleString(`i { font-family: ${window.getComputedStyle(document.getElementsByTagName('i')[b]).getPropertyValue("font-family")} !important }`);
      a = 1;
    }
  }

})();
