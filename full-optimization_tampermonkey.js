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
  addStyleString(`* { font-variant-ligatures: normal !important }`);
  addStyleString(`* { font-variant-numeric: lining-nums !important; font-feature-settings: "lnum" !important; }`);

  var a;
  var b = 0;

  var c;
  var d = 0;

  var x;
  var y = 0;
  var regex = '/Andika|Lexend|Uniqlo|sst|YouTube|YT|speedee|Twitter|spotify|Samsung|Netflix|Amazon|CNN|adobe|intel|Reith|knowledge|abc|Yahoo|VICE|Google|GS Text|Android|bwi|Market|Razer|peacock|zilla|DDG|Bogle|tpu|ArtifaktElement|LG|GeForce|Sky|F1|Indy|Guardian|nyt|Times|Beaufort for LOL|MB|SF|Inter|Adelle|Barlow|Roboto|Avenir|Raleway|Proxima|Gotham|Futura|IBM|Clear Sans|Karla|Work Sans|Segoe|Selawik|WeblySleek|Commissioner|Oxygen|Myriad|Lucida|Lato|Nunito|Whitney|Motiva|Montserrat|PT|Fira|Ubuntu|Source|Noto|Open Sans|Droid Sans|Museo|DIN|Keiner|Kenyan Coffee|Oswald|Rubik|Industry|Rajdhani|Saira|Klavika|Chakra Petch|Univers|Franklin|Impact|Impacted|Poppins|Roobert|Circular|Manrope|Benton|Mark|Helvetica|Archivo|Sora|Interstate|Helmet|Arial|Arimo|Rodin|Hiragino|Yu|Gothic A1|Yantramanav|Komika|Bitter|Playfair|Lora|Linux|Shippori|artifakt|ヒラギノ角ゴ/'
  var runesConst = ",Material Icons Extended, Material Icons, Google Material Icons, Material Design Icons, VideoJS, nexticon";
  var preCompute = document.documentElement.innerHTML;

  while (a != 1 && b <= 1) {
    if (`${'/<h2>/'}.test(preCompute) != 'undefined' && ${'/<h2>/'}.test(preCompute) != null`) {
      var font = window.getComputedStyle(document.getElementsByTagName('h2')[b]).getPropertyValue("font-family");
      if (`${regex}.test(font)`) {
        var font = font + runesConst;
        var runesElement = document.getElementsByTagName('i')[b];
        if (typeof(runesElement) != 'undefined' && runesElement != null) {
          var runes = window.getComputedStyle(runesElement).getPropertyValue("font-family");
          var font = font + "," + runes;
          addStyleString(`* { font-family: ${font} !important }`);
          a = 1;
          return;
        }
        var runesElement = document.getElementsByTagName('span')[b];
        if (typeof(runesElement) != 'undefined' && runesElement != null) {
          var runes = window.getComputedStyle(runesElement).getPropertyValue("font-family");
          var font = font + "," + runes;
          addStyleString(`* { font-family: ${font} !important }`);
          a = 1;
          return;
        }
        addStyleString(`* { font-family: ${font} !important }`);
        a = 1;
        return;
      } else {
        b++;
      }
    }
  }

  while (c != 1 && d <= 1) {
    if (`${'/<h1>/'}.test(preCompute) != 'undefined' && ${'/<h1>/'}.test(preCompute) != null`) {
      var font = window.getComputedStyle(document.getElementsByTagName('h1')[d]).getPropertyValue("font-family");
      if (`${regex}.test(font)`) {
        var font = font + runesConst;
        var runesElement = document.getElementsByTagName('i')[d];
        if (typeof(runesElement) != 'undefined' && runesElement != null) {
          var runes = window.getComputedStyle(runesElement).getPropertyValue("font-family");
          var font = font + "," + runes;
          addStyleString(`* { font-family: ${font} !important }`);
          c = 1;
          return;
        }
        var runesElement = document.getElementsByTagName('span')[d];
        if (typeof(runesElement) != 'undefined' && runesElement != null) {
          var runes = window.getComputedStyle(runesElement).getPropertyValue("font-family");
          var font = font + "," + runes;
          addStyleString(`* { font-family: ${font} !important }`);
          c = 1;
          return;
        }
        addStyleString(`* { font-family: ${font} !important }`);
        c = 1;
        return;
      } else {
        d++;
      }
    }
  }

  while (x != 1 && y <= 1) {
    if (`${'/<p>/'}.test(preCompute) != 'undefined' && ${'/<p>/'}.test(preCompute) != null`) {
      var font = window.getComputedStyle(document.getElementsByTagName('p')[y]).getPropertyValue("font-family");
      if (`${regex}.test(font)`) {
        var font = font + runesConst;
        var runesElement = document.getElementsByTagName('i')[y];
        if (typeof(runesElement) != 'undefined' && runesElement != null) {
          var runes = window.getComputedStyle(runesElement).getPropertyValue("font-family");
          var font = font + "," + runes;
          addStyleString(`* { font-family: ${font} !important }`);
          x = 1;
          return;
        }
        var runesElement = document.getElementsByTagName('span')[y];
        if (typeof(runesElement) != 'undefined' && runesElement != null) {
          var runes = window.getComputedStyle(runesElement).getPropertyValue("font-family");
          var font = font + "," + runes;
          addStyleString(`* { font-family: ${font} !important }`);
          x = 1;
          return;
        }
        addStyleString(`* { font-family: ${font} !important }`);
        x = 1;
        return;
      } else {
        y++;
      }
    }
  }

})();
