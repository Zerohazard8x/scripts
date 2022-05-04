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

  var x;
  var y = 0;

  var runes = 'ForkAwesome, FontAwesome, FontAwesomeBrands, FontAwesomeSolid, "Font Awesome 5 Free", "Font Awesome 5 Pro", "Font Awesome 5 Brands", ui-icons, docons, Material Icons Extended, Material Icons, Google Material Icons, Material Design Icons, ddg-serp-icons, ktplayer, VideoJS, "glyphicons halflings", FabricMDL2Icons, DotNet MDL2 Assets, shared-icons, gsmarena, tinymce, brie-icon, dcg-icons, icomoon, Icons, brand-icons, MWF-MDL2, iconfont, nlifecms, element-icons, Flaticon, tipi, zwicon, eg-header-icomoon, eg-footer-icomoon, simple-line-icons, Bitly Icon, Deezer Icons, "SS Social", rtings-icons, tgico, Mcd-Icons, Shopkeeper-Icon-Font, primeicons, uniqlo-icons, editormd-logo, ElegantIcons, glyphicons Regular, Twitter Color Emoji, icon-moon, NextIcon, lazada-member, NucleoIcons';
  var regex = '/Andika|Lexend|Uniqlo|sst|YouTube|YT|speedee|Twitter|spotify|Samsung|Netflix|Amazon|CNN|adobe|intel|Reith|knowledge|abc|Yahoo|VICE|Google|GS Text|Android|bwi|Market|Razer|peacock|zilla|DDG|Bogle|tpu|ArtifaktElement|LG|GeForce|Sky|F1|Indy|Guardian|nyt|Times|Beaufort for LOL|MB|SF|Inter|Adelle|Barlow|Roboto|Avenir|Raleway|Proxima|Gotham|Futura|IBM|Clear Sans|Karla|Work Sans|Segoe|Selawik|WeblySleek|Commissioner|Oxygen|Myriad|Lucida|Lato|Nunito|Whitney|Motiva|Montserrat|PT|Fira|Ubuntu|Source|Noto|Open Sans|Droid Sans|Museo|DIN|Keiner|Kenyan Coffee|Oswald|Rubik|Industry|Rajdhani|Saira|Klavika|Chakra Petch|Univers|Franklin|Impact|Impacted|Poppins|Roobert|Circular|Manrope|Benton|Mark|Helvetica|Archivo|Sora|Interstate|Helmet|Arial|Arimo|Rodin|Hiragino|Yu|Gothic A1|Yantramanav|Komika|Bitter|Playfair|Lora|Linux|Shippori|artifakt|ヒラギノ角ゴ/'

  while (x != 1 && y <= 1) {
    var font = window.getComputedStyle(document.getElementsByTagName('h1')[y]).getPropertyValue("font-family");
    if (`${regex}.test(font)`) {
      addStyleString(`* { font-family: ${font}, ${runes} !important }`);
      addStyleString(`i { font-family: ${runes} !important }`);
      x=1;
    } else {
      y++;
    }
    break;
  }

  while (a != 1 && b <= 1) {
    var font = window.getComputedStyle(document.getElementsByTagName('p')[b]).getPropertyValue("font-family");
    if (`${regex}.test(font)`) {
      addStyleString(`* { font-family: ${font}, ${runes} !important }`);
      addStyleString(`i { font-family: ${runes} !important }`);
      a=1;
    } else {
      b++;
    }
    break;
  }

})();
