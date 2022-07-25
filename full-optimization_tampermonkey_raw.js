// ==UserScript==
// @name        Zerohazard's Font Script
// @author      twitter @Zerohazard8x
// ==/UserScript==

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

var regex =
  "/Andika|Lexend|Uniqlo|sst|YouTube|YT|speedee|Twitter|spotify|Samsung|Netflix|Amazon|CNN|adobe|intel|Reith|knowledge|abc|Yahoo|VICE|Google|GS|Android|bwi|Market|Razer|peacock|zilla|DDG|Bogle|tpu|Artifakt|LG|GeForce|Sky|F1|Indy|Guardian|nyt|Times|Beaufort|MB|SF|Inter|Adelle|Barlow|Roboto|Avenir|Raleway|Proxima|Gotham|Futura|Plex|Clear|Karla|Work|Segoe|Selawik|WeblySleek|Frutiger|Commissioner|Oxygen|Myriad|Lucida|Lato|Nunito|Whitney|Motiva|Montserrat|PT|Fira|Ubuntu|Source|Noto|Open Sans|Droid Sans|Museo|DIN|Keiner|Coffee|Oswald|Rubik|Industry|Rajdhani|Saira|Klavika|Petch|Univers|Franklin|Tahoma|Verdana|Impact|Impacted|Poppins|Roobert|Circular|Manrope|Benton|Mark|Helvetica|Archivo|Sora|Interstate|Helmet|Arial|Arimo|Rodin|Hiragino|Yu|Gothic|Yantramanav|Komika|Bitter|Playfair|Lora|Linux|Shippori|artifakt|ヒラギノ角ゴ/";
var runes =
  "Material Icons Extended, Material Icons, Google Material Icons, Material Design Icons, rtings-icons, VideoJS";
var preCompute = document.documentElement.innerHTML;

var a;
var b;
var c;
var d;

var compReps = 0;
var compRepsOrig = compReps;

if (`preCompute.contains("<i>") === true`) {
  var runesElement = document.getElementsByTagName("i")[compReps];
  if (typeof runesElement != "undefined" && runesElement != null) {
    var runes =
      runes +
      "," +
      window.getComputedStyle(runesElement).getPropertyValue("font-family");
  }
}
if (`preCompute.contains("<button>") === true`) {
  var runesElement = document.getElementsByTagName("button")[compReps];
  if (typeof runesElement != "undefined" && runesElement != null) {
    var runes =
      runes +
      "," +
      window.getComputedStyle(runesElement).getPropertyValue("font-family");
  }
}
if (`preCompute.contains("<span>") === true`) {
  var runesElement = document.getElementsByTagName("span")[compReps];
  if (typeof runesElement != "undefined" && runesElement != null) {
    var runes =
      runes +
      "," +
      window.getComputedStyle(runesElement).getPropertyValue("font-family");
  }
}

function runesFunc() {
  addStyleString(`i { font-family: ${runes}, ${font} !important }`);
  addStyleString(`button { font-family: ${runes}, ${font} !important }`);
  addStyleString(`span { font-family: ${runes}, ${font} !important }`);
}

if (`preCompute.contains("<h2>") === true`) {
  while (b != 1 && compReps <= 1) {
    var font = window
      .getComputedStyle(document.getElementsByTagName("h2")[compReps])
      .getPropertyValue("font-family");
    if (`${font} != 'undefined' && ${font} != null && ${regex}.test(font)`) {
      addStyleString(`* { font-family: ${font}, ${runes} !important }`);
      runesFunc();
      throw Error();
      b = 1;
      compReps = compRepsOrig;
    } else {
      compReps++;
    }
  }
}

if (`preCompute.contains("<h1>") === true`) {
  while (c != 1 && compReps <= 1) {
    var font = window
      .getComputedStyle(document.getElementsByTagName("h1")[compReps])
      .getPropertyValue("font-family");
    if (`${font} != 'undefined' && ${font} != null && ${regex}.test(font)`) {
      addStyleString(`* { font-family: ${font}, ${runes} !important }`);
      runesFunc();
      throw Error();
      c = 1;
      compReps = compRepsOrig;
    } else {
      compReps++;
    }
  }
}

if (`preCompute.contains("<p>") === true`) {
  while (d != 1 && compReps <= 1) {
    var font = window
      .getComputedStyle(document.getElementsByTagName("p")[compReps])
      .getPropertyValue("font-family");
    if (`${font} != 'undefined' && ${font} != null && ${regex}.test(font)`) {
      addStyleString(`* { font-family: ${font}, ${runes} !important }`);
      runesFunc();
      throw Error();
      d = 1;
      compReps = compRepsOrig;
    } else {
      compReps++;
    }
  }
}

if (`preCompute.contains("<div>") === true`) {
  while (a != 1 && compReps <= 1) {
    var font = window
      .getComputedStyle(document.getElementsByTagName("div")[compReps])
      .getPropertyValue("font-family");
    if (`${font} != 'undefined' && ${font} != null && ${regex}.test(font)`) {
      addStyleString(`* { font-family: ${font}, ${runes} !important }`);
      runesFunc();
      throw Error();
      a = 1;
      compReps = compRepsOrig;
    } else {
      compReps++;
    }
  }
}
