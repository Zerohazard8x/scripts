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
    addStyleString(`* { font-variant-ligatures: common-ligatures, contextual !important }`);
    addStyleString(`* { font-variant-numeric: lining-nums, tabular-nums !important }`);
    addStyleString(`* { font-feature-settings: "kern", "liga", "clig", "calt", "lnum", "tnum" !important }`);
    addStyleString(`* { font-kerning: normal !important }`);

    var a;
    var b;
    var c;

    var compReps = 0;
    var compRepsOrig = compReps;

    var regex = '/Andika|Lexend|Uniqlo|sst|YouTube|YT|speedee|Twitter|spotify|Samsung|Netflix|Amazon|CNN|adobe|intel|Reith|knowledge|abc|Yahoo|VICE|Google|GS Text|Android|bwi|Market|Razer|peacock|zilla|DDG|Bogle|tpu|ArtifaktElement|LG|GeForce|Sky|F1|Indy|Guardian|nyt|Times|Beaufort for LOL|MB|SF|Inter|Adelle|Barlow|Roboto|Avenir|Raleway|Proxima|Gotham|Futura|IBM|Clear Sans|Karla|Work Sans|Segoe|Selawik|WeblySleek|Frutiger|Commissioner|Oxygen|Myriad|Lucida|Lato|Nunito|Whitney|Motiva|Montserrat|PT|Fira|Ubuntu|Source|Noto|Open Sans|Droid Sans|Museo|DIN|Keiner|Coffee|Oswald|Rubik|Industry|Rajdhani|Saira|Klavika|Chakra Petch|Univers|Franklin|Tahoma|Verdana|Impact|Impacted|Poppins|Roobert|Circular|Manrope|Benton|Mark|Helvetica|Archivo|Sora|Interstate|Helmet|Arial|Arimo|Rodin|Hiragino|Yu|Gothic A1|Yantramanav|Komika|Bitter|Playfair|Lora|Linux|Shippori|artifakt|ヒラギノ角ゴ/'
    var runesConst = ",Material Icons Extended, Material Icons, Google Material Icons, Material Design Icons, rtings-icons, VideoJS";
    var preCompute = document.documentElement.innerHTML;

    var runesElement = document.getElementsByTagName('i')[compReps];
    if (typeof(runesElement) != 'undefined' && runesElement != null) {
        var runes = window.getComputedStyle(runesElement).getPropertyValue("font-family");
    }
    var runesElement = document.getElementsByTagName('button')[compReps];
    if (typeof(runesElement) != 'undefined' && runesElement != null) {
        var runes = window.getComputedStyle(runesElement).getPropertyValue("font-family");
    }
    var runesElement = document.getElementsByTagName('span')[compReps];
    if (typeof(runesElement) != 'undefined' && runesElement != null) {
        var runes = window.getComputedStyle(runesElement).getPropertyValue("font-family");
    }

    if (`preCompute.contains("<h2>") != 'undefined' && preCompute.contains("<h2>") != null`) {
        while (a != 1 && compReps <= 1) {
            var font = window.getComputedStyle(document.getElementsByTagName('h2')[compReps]).getPropertyValue("font-family");
            if (`${regex}.test(font)`) {
                var font = font + runesConst;
                addStyleString(`* { font-family: ${font}, ${runes} !important }`);
                a = 1;
                compReps = compRepsOrig;
            } else {
                compReps++;
            }
        }
    }

    if (`preCompute.contains("<h1>") != 'undefined' && preCompute.contains("<h1>") != null`) {
        while (b != 1 && compReps <= 1) {
            var font = window.getComputedStyle(document.getElementsByTagName('h1')[compReps]).getPropertyValue("font-family");
            if (`${regex}.test(font)`) {
                var font = font + runesConst;
                addStyleString(`* { font-family: ${font}, ${runes} !important }`);
                b = 1;
                compReps = compRepsOrig;
            } else {
                compReps++;
            }
        }
    }

    if (`preCompute.contains("<p>") != 'undefined' && preCompute.contains("<p>") != null`) {
        while (c != 1 && compReps <= 1) {
            var font = window.getComputedStyle(document.getElementsByTagName('p')[compReps]).getPropertyValue("font-family");
            if (`${regex}.test(font)`) {
                var font = font + runesConst;
                addStyleString(`* { font-family: ${font}, ${runes} !important }`);
                c = 1;
                compReps = compRepsOrig;
            } else {
                compReps++;
            }
        }

    }

    addStyleString(`i { font-family: ${runes}, ${font} !important }`);
    addStyleString(`button { font-family: ${runes}, ${font} !important }`);
    addStyleString(`span { font-family: ${runes}, ${font} !important }`);

})();
