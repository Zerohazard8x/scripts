// ==UserScript==
// @name        Zerohazard's Font Script
// @author      twitter @Zerohazard8x
// @match       *://*/*
// @grant       GM_addStyle
// @grant       GM_getValue
// @grant       GM_setValue
// @grant       GM_xmlhttpRequest
// ==/UserScript==

var preCompute = document.documentElement.innerHTML;
var preComputeCheck = document.documentElement.innerHTML;
while (preCompute != preComputeCheck) {
    if (preCompute == preComputeCheck && typeof preCompute != "undefined" && preCompute != null) {
        break;
    }
    var preCompute = document.documentElement.innerHTML;
    var preComputeCheck = document.documentElement.innerHTML;
}

if (preCompute.includes("<h2>") === false && preCompute.includes("<h1>") === false && preCompute.includes("<p>") === false && preCompute.includes("<body>") === false) {
    throw Error();
} else {
    function addStyleString(str) {
        var node = document.createElement("style");
        node.innerHTML = str;
        document.body.appendChild(node);
    }

    var regex =
        "/.*conso.*|.*ika.*|.*Lex.*|.*qlo.*|.*sst.*|.*ube.*|.*YT.*|.*eedee.*|.*tter.*|.*ify.*|.*sung.*|.*flix.*|.*zon.*|.*CNN.*|.*obe.*|.*tel.*|.*Reith.*|.*ledge.*|.*abc.*|.*ahoo.*|.*VICE.*|.*gle.*|.*GS.*|.*roid.*|.*bwi.*|.*rket.*|.*zer.*|.*ock.*|.*zilla.*|.*DDG.*|.*tpu.*|.*fakt.*|.*LG.*|.*rce.*|.*Sky.*|.*F1.*|.*ndy.*|.*rdian.*|.*nyt.*|.*ime.*|.*Beau.*|.*MB.*|.*SF.*|.*Inter.*|.*lle.*|.*low.*|.*enir.*|.*Rale.*|.*xima.*|.*tham.*|.*tura.*|.*ear.*|.*arla.*|.*Work.*|.*goe.*|.*wik.*|.*eek.*|.*ger.*|.*ner.*|.*gen.*|.*iad.*|.*cida.*|.*Lato.*|.*Nunito.*|.*tney.*|.*otiva.*|.*serrat.*|.*PT.*|.*ira.*|.*untu.*|.*oto.*|.*Open.*|.*oid.*|.*useo.*|.*DIN.*|.*iner.*|.*offee.*|.*ald.*|.*Rubik.*|.*ustry.*|.*ani.*|.*Petch.*|.*nivers.*|.*lin.*|.*oma.*|.*rdana.*|.*pact.*|.*pins.*|.*bert.*|.*cular.*|.*ope.*|.*nto.*|.*Mark.*|.*lvetica.*|.ivo.*|.*ora.*|.*tate.*|.*met.*|.*Arial.*|.*Arimo.*|.*Rodin.*|.*no.*|.*Yu.*|.*ic.*|.*manav.*|.*Bitter.*|.*air.*|.*Lora.*|.*pori.*|.*角/mi"
    var runes =
        "Material Icons Extended, Material Icons, Google Material Icons, Material Design Icons, rtings-icons, VideoJS";

    var killVar = 0;
    const killVarOrig = killVar;

    var compReps = 0;
    var compRepsLimit = 1;
    const compRepsOrig = compReps;

    function runesFunc() {
        var ligaCheck = segConst.getPropertyValue("font-variant-ligatures");
        if (typeof ligaCheck != "undefined" && ligaCheck != null) {
            addStyleString(`* { font-variant-ligatures: ${ligaCheck} !important }`);
            var numeCheck = segConst.getPropertyValue("font-variant-numeric");
            if (typeof numeCheck != "undefined" && numeCheck != null) {
                addStyleString(`* { font-variant-numeric: ${numeCheck} !important }`);
            }
            var ftureCheck = segConst.getPropertyValue("font-feature-settings");
            if (typeof ftureCheck != "undefined" && ftureCheck != null) {
                addStyleString(`* { font-feature-settings: ${ftureCheck} !important }`);
            }
            var kernCheck = segConst.getPropertyValue("font-kerning");
            if (typeof kernCheck != "undefined" && kernCheck != null) {
                addStyleString(`* { font-kerning: ${kernCheck} !important }`);
            }
        }
        if (`preCompute.includes("<i>") === true`) {
            var runesElement = document.getElementsByTagName("i")[0];
            if (typeof runesElement != "undefined" && runesElement != null) {
                var runes =
                    runes +
                    "," +
                    window.getComputedStyle(runesElement).getPropertyValue("font-family");
            }
        } else if (`preCompute.includes("<span>") === true`) {
            var runesElement = document.getElementsByTagName("span")[0];
            if (typeof runesElement != "undefined" && runesElement != null) {
                var runes =
                    runes +
                    "," +
                    window.getComputedStyle(runesElement).getPropertyValue("font-family");
            }
        } else if (`preCompute.includes("<button>") === true`) {
            var runesElement = document.getElementsByTagName("button")[0];
            if (typeof runesElement != "undefined" && runesElement != null) {
                var runes =
                    runes +
                    "," +
                    window.getComputedStyle(runesElement).getPropertyValue("font-family");
            }
        }
        addStyleString(`* { font-family: ${font}, ${runes} !important }`);
        addStyleString(`i { font-family: ${runes}, ${font} !important }`);
        addStyleString(`span { font-family: ${runes}, ${font} !important }`);
        addStyleString(`button { font-family: ${runes}, ${font} !important }`);
    }

    if (`preCompute.includes("<body>") === true`) {
        compReps = compRepsOrig;
        killVar = killVarOrig;
        while (killVar != 1 && compReps != compRepsLimit) {
            var font = window
                .getComputedStyle(document.getElementsByTagName("body")[compReps])
                .getPropertyValue("font-family");
            if (
                `typeof ${font} != "undefined" && ${font} != null && ${regex}.test(font)`
            ) {
                var segConst = window.getComputedStyle(
                    document.getElementsByTagName("body")[compReps]
                );
                runesFunc();
                throw Error();
                killVar = 1;
            } else {
                compReps++;
            }
        }
        throw Error();
    } else if (`preCompute.includes("<h2>") === true`) {
        compReps = compRepsOrig;
        killVar = killVarOrig;
        while (killVar != 1 && compReps != compRepsLimit) {
            var font = window
                .getComputedStyle(document.getElementsByTagName("h2")[compReps])
                .getPropertyValue("font-family");
            if (
                `typeof ${font} != "undefined" && ${font} != null && ${regex}.test(font)`
            ) {
                var segConst = window.getComputedStyle(
                    document.getElementsByTagName("h2")[compReps]
                );
                runesFunc();
                throw Error();
                killVar = 1;
            } else {
                compReps++;
            }
        }
        throw Error();
    } else if (`preCompute.includes("<h1>") === true`) {
        compReps = compRepsOrig;
        killVar = killVarOrig;
        while (killVar != 1 && compReps != compRepsLimit) {
            var font = window
                .getComputedStyle(document.getElementsByTagName("h1")[compReps])
                .getPropertyValue("font-family");
            if (
                `typeof ${font} != "undefined" && ${font} != null && ${regex}.test(font)`
            ) {
                var segConst = window.getComputedStyle(
                    document.getElementsByTagName("h1")[compReps]
                );
                runesFunc();
                throw Error();
            } else {
                compReps++;
            }
        }
        throw Error();
    } else if (`preCompute.includes("<p>") === true`) {
        compReps = compRepsOrig;
        killVar = killVarOrig;
        while (killVar != 1 && compReps != compRepsLimit) {
            var font = window
                .getComputedStyle(document.getElementsByTagName("p")[compReps])
                .getPropertyValue("font-family");
            if (
                `typeof ${font} != "undefined" && ${font} != null && ${regex}.test(font)`
            ) {
                var segConst = window.getComputedStyle(
                    document.getElementsByTagName("p")[compReps]
                );
                runesFunc();
                throw Error();
            } else {
                compReps++;
            }
        }
        throw Error();
    }
}
