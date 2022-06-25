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

(function(){'use strict';function s(t){var e=document.createElement('style');e.innerHTML=t,document.body.appendChild(e)}s(`* { font-variant-ligatures: common-ligatures, contextual !important }`),s(`* { font-variant-numeric: lining-nums, tabular-nums !important }`),s(`* { font-feature-settings: "kern", "liga", "clig", "calt", "lnum", "tnum" !important }`),s(`* { font-kerning: normal !important }`);var t,n,o,c,l,d,e=0,r=e,a='/Andika|Lexend|Uniqlo|sst|YouTube|YT|speedee|Twitter|spotify|Samsung|Netflix|Amazon|CNN|adobe|intel|Reith|knowledge|abc|Yahoo|VICE|Google|GS Text|Android|bwi|Market|Razer|peacock|zilla|DDG|Bogle|tpu|ArtifaktElement|LG|GeForce|Sky|F1|Indy|Guardian|nyt|Times|Beaufort for LOL|MB|SF|Inter|Adelle|Barlow|Roboto|Avenir|Raleway|Proxima|Gotham|Futura|IBM|Clear Sans|Karla|Work Sans|Segoe|Selawik|WeblySleek|Frutiger|Commissioner|Oxygen|Myriad|Lucida|Lato|Nunito|Whitney|Motiva|Montserrat|PT|Fira|Ubuntu|Source|Noto|Open Sans|Droid Sans|Museo|DIN|Keiner|Coffee|Oswald|Rubik|Industry|Rajdhani|Saira|Klavika|Chakra Petch|Univers|Franklin|Tahoma|Verdana|Impact|Impacted|Poppins|Roobert|Circular|Manrope|Benton|Mark|Helvetica|Archivo|Sora|Interstate|Helmet|Arial|Arimo|Rodin|Hiragino|Yu|Gothic A1|Yantramanav|Komika|Bitter|Playfair|Lora|Linux|Shippori|artifakt|ヒラギノ角ゴ/',i=",Material Icons Extended, Material Icons, Google Material Icons, Material Design Icons, rtings-icons, VideoJS",u=document.documentElement.innerHTML;if(`preCompute.contains("<i>") != 'undefined' && preCompute.contains("<i>") != null`&&(n=document.getElementsByTagName('i')[e],typeof n!='undefined'&&n!=null&&(o=window.getComputedStyle(n).getPropertyValue("font-family"))),`preCompute.contains("<button>") != 'undefined' && preCompute.contains("<button>") != null`&&(n=document.getElementsByTagName('button')[e],typeof n!='undefined'&&n!=null&&(o=window.getComputedStyle(n).getPropertyValue("font-family"))),`preCompute.contains("<span>") != 'undefined' && preCompute.contains("<span>") != null`&&(n=document.getElementsByTagName('span')[e],typeof n!='undefined'&&n!=null&&(o=window.getComputedStyle(n).getPropertyValue("font-family"))),`preCompute.contains("<h2>") != 'undefined' && preCompute.contains("<h2>") != null`)for(;l!=1&&e<=1;)t=window.getComputedStyle(document.getElementsByTagName('h2')[e]).getPropertyValue("font-family"),`${a}.test(font)`?(t=t+i,s(`* { font-family: ${t}, ${o} !important }`),l=1,e=r):e++;if(`preCompute.contains("<h1>") != 'undefined' && preCompute.contains("<h1>") != null`)for(;c!=1&&e<=1;)t=window.getComputedStyle(document.getElementsByTagName('h1')[e]).getPropertyValue("font-family"),`${a}.test(font)`?(t=t+i,s(`* { font-family: ${t}, ${o} !important }`),c=1,e=r):e++;if(`preCompute.contains("<p>") != 'undefined' && preCompute.contains("<p>") != null`)for(;d!=1&&e<=1;)t=window.getComputedStyle(document.getElementsByTagName('p')[e]).getPropertyValue("font-family"),`${a}.test(font)`?(t=t+i,s(`* { font-family: ${t}, ${o} !important }`),d=1,e=r):e++;s(`i { font-family: ${o}, ${t} !important }`),s(`button { font-family: ${o}, ${t} !important }`),s(`span { font-family: ${o}, ${t} !important }`)})()
