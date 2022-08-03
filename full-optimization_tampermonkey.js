// ==UserScript==
// @name        Zerohazard's Font Script
// @author      twitter @Zerohazard8x
// ==/UserScript==

function addStyleString(e){var t=document.createElement("style");t.innerHTML=e,document.body.appendChild(t)}var regex="/Andika|Lexend|Uniqlo|sst|YouTube|YT|speedee|Twitter|spotify|Samsung|Netflix|Amazon|CNN|adobe|intel|Reith|knowledge|abc|Yahoo|VICE|Google|GS|Android|bwi|Market|Razer|peacock|zilla|DDG|Bogle|tpu|Artifakt|LG|GeForce|Sky|F1|Indy|Guardian|nyt|Times|Beaufort|MB|SF|Inter|Adelle|Barlow|Roboto|Avenir|Raleway|Proxima|Gotham|Futura|Plex|Clear|Karla|Work|Segoe|Selawik|WeblySleek|Frutiger|Commissioner|Oxygen|Myriad|Lucida|Lato|Nunito|Whitney|Motiva|Montserrat|PT|Fira|Ubuntu|Source|Noto|Open|Droid Sans|Museo|DIN|Keiner|Coffee|Oswald|Rubik|Industry|Rajdhani|Saira|Klavika|Petch|Univers|Franklin|Tahoma|Verdana|Impact|Impacted|Poppins|Roobert|Circular|Manrope|Benton|Mark|Helvetica|Archivo|Sora|Interstate|Helmet|Arial|Arimo|Rodin|Hiragino|Yu|Gothic|Yantramanav|Komika|Bitter|Playfair|Lora|Linux|Shippori|artifakt|ヒラギノ角ゴ/",compReps,compRepsLimit,font,ligaCheck,numeCheck,ftureCheck,kernCheck,runes="Material Icons Extended, Material Icons, Google Material Icons, Material Design Icons, rtings-icons, VideoJS",preCompute=document.documentElement.innerHTML,killVar=0;const killVarOrig=killVar;compReps=0,compRepsLimit=1;const compRepsOrig=compReps;if(`preCompute.contains("<i>") === true`){const e=document.getElementsByTagName("i")[0];typeof e!="undefined"&&e!=null&&(runes=runes+","+window.getComputedStyle(e).getPropertyValue("font-family"))}if(`preCompute.contains("<button>") === true`){const e=document.getElementsByTagName("button")[0];typeof e!="undefined"&&e!=null&&(runes=runes+","+window.getComputedStyle(e).getPropertyValue("font-family"))}function runesFunc(){addStyleString(`i { font-family: ${runes}, ${font} !important }`),addStyleString(`button { font-family: ${runes}, ${font} !important }`)}if(`preCompute.contains("<h2>") === true`){for(;killVar!=1&&compReps!=compRepsLimit;)if(font=window.getComputedStyle(document.getElementsByTagName("h2")[compReps]).getPropertyValue("font-family"),`typeof ${font} != "undefined" && ${font} != null && ${regex}.test(font)`){const e=window.getComputedStyle(document.getElementsByTagName("h2")[compReps]);throw ligaCheck=e.getPropertyValue("font-variant-ligatures"),`${ligaCheck} != 'undefined' && ${ligaCheck} != null`&&(addStyleString(`* { font-variant-ligatures: ${ligaCheck} !important }`),numeCheck=e.getPropertyValue("font-variant-numeric"),`${numeCheck} != 'undefined' && ${numeCheck} != null`&&addStyleString(`* { font-variant-numeric: ${numeCheck} !important }`),ftureCheck=e.getPropertyValue("font-feature-settings"),`${ftureCheck} != 'undefined' && ${ftureCheck} != null`&&addStyleString(`* { font-feature-settings: ${ftureCheck} !important }`),kernCheck=e.getPropertyValue("font-kerning"),`${kernCheck} != 'undefined' && ${kernCheck} != null`&&addStyleString(`* { font-kerning: ${kernCheck} !important }`)),addStyleString(`* { font-family: ${font}, ${runes} !important }`),runesFunc(),Error();killVar=1}else compReps++;throw Error()}if(compReps=compRepsOrig,killVar=killVarOrig,`preCompute.contains("<h1>") === true`){for(;killVar!=1&&compReps!=compRepsLimit;)if(font=window.getComputedStyle(document.getElementsByTagName("h1")[compReps]).getPropertyValue("font-family"),`typeof ${font} != "undefined" && ${font} != null && ${regex}.test(font)`){const e=window.getComputedStyle(document.getElementsByTagName("h1")[compReps]);throw ligaCheck=e.getPropertyValue("font-variant-ligatures"),`${ligaCheck} != 'undefined' && ${ligaCheck} != null`&&(addStyleString(`* { font-variant-ligatures: ${ligaCheck} !important }`),numeCheck=e.getPropertyValue("font-variant-numeric"),`${numeCheck} != 'undefined' && ${numeCheck} != null`&&addStyleString(`* { font-variant-numeric: ${numeCheck} !important }`),ftureCheck=e.getPropertyValue("font-feature-settings"),`${ftureCheck} != 'undefined' && ${ftureCheck} != null`&&addStyleString(`* { font-feature-settings: ${ftureCheck} !important }`),kernCheck=e.getPropertyValue("font-kerning"),`${kernCheck} != 'undefined' && ${kernCheck} != null`&&addStyleString(`* { font-kerning: ${kernCheck} !important }`)),addStyleString(`* { font-family: ${font}, ${runes} !important }`),runesFunc(),Error();killVar=1}else compReps++;throw Error()}if(compReps=compRepsOrig,killVar=killVarOrig,`preCompute.contains("<p>") === true`){for(;killVar!=1&&compReps!=compRepsLimit;)if(font=window.getComputedStyle(document.getElementsByTagName("p")[compReps]).getPropertyValue("font-family"),`typeof ${font} != "undefined" && ${font} != null && ${regex}.test(font)`){const e=window.getComputedStyle(document.getElementsByTagName("p")[compReps]);throw ligaCheck=e.getPropertyValue("font-variant-ligatures"),`${ligaCheck} != 'undefined' && ${ligaCheck} != null`&&(addStyleString(`* { font-variant-ligatures: ${ligaCheck} !important }`),numeCheck=e.getPropertyValue("font-variant-numeric"),`${numeCheck} != 'undefined' && ${numeCheck} != null`&&addStyleString(`* { font-variant-numeric: ${numeCheck} !important }`),ftureCheck=e.getPropertyValue("font-feature-settings"),`${ftureCheck} != 'undefined' && ${ftureCheck} != null`&&addStyleString(`* { font-feature-settings: ${ftureCheck} !important }`),kernCheck=e.getPropertyValue("font-kerning"),`${kernCheck} != 'undefined' && ${kernCheck} != null`&&addStyleString(`* { font-kerning: ${kernCheck} !important }`)),addStyleString(`* { font-family: ${font}, ${runes} !important }`),runesFunc(),Error();killVar=1}else compReps++;throw Error()}if(compReps=compRepsOrig,killVar=killVarOrig,`preCompute.contains("<body>") === true`){for(;killVar!=1&&compReps!=compRepsLimit;)if(font=window.getComputedStyle(document.getElementsByTagName("body")[compReps]).getPropertyValue("font-family"),`typeof ${font} != "undefined" && ${font} != null && ${regex}.test(font)`){const e=window.getComputedStyle(document.getElementsByTagName("body")[compReps]);throw ligaCheck=e.getPropertyValue("font-variant-ligatures"),`${ligaCheck} != 'undefined' && ${ligaCheck} != null`&&(addStyleString(`* { font-variant-ligatures: ${ligaCheck} !important }`),numeCheck=e.getPropertyValue("font-variant-numeric"),`${numeCheck} != 'undefined' && ${numeCheck} != null`&&addStyleString(`* { font-variant-numeric: ${numeCheck} !important }`),ftureCheck=e.getPropertyValue("font-feature-settings"),`${ftureCheck} != 'undefined' && ${ftureCheck} != null`&&addStyleString(`* { font-feature-settings: ${ftureCheck} !important }`),kernCheck=e.getPropertyValue("font-kerning"),`${kernCheck} != 'undefined' && ${kernCheck} != null`&&addStyleString(`* { font-kerning: ${kernCheck} !important }`)),addStyleString(`* { font-family: ${font}, ${runes} !important }`),runesFunc(),Error();killVar=1}else compReps++;throw Error()}
