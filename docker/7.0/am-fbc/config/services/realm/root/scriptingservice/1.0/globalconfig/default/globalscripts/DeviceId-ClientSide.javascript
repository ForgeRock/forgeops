var fontDetector = (function () {
    /**
     * JavaScript code to detect available availability of a
     * particular font in a browser using JavaScript and CSS.
     *
     * Author : Lalit Patel
     * Website: http://www.lalit.org/lab/javascript-css-font-detect/
     * License: Apache Software License 2.0
     *          http://www.apache.org/licenses/LICENSE-2.0
     * Version: 0.15 (21 Sep 2009)
     *          Changed comparision font to default from sans-default-default,
     *          as in FF3.0 font of child element didn't fallback
     *          to parent element if the font is missing.
     * Version: 0.2 (04 Mar 2012)
     *          Comparing font against all the 3 generic font families ie,
     *          'monospace', 'sans-serif' and 'sans'. If it doesn't match all 3
     *          then that font is 100% not available in the system
     * Version: 0.3 (24 Mar 2012)
     *          Replaced sans with serif in the list of baseFonts
     */
    /*
     * Portions Copyrighted 2013 ForgeRock AS.
     */
    var detector = {}, baseFonts, testString, testSize, h, s, defaultWidth = {}, defaultHeight = {}, index;

    // a font will be compared against all the three default fonts.
    // and if it doesn't match all 3 then that font is not available.
    baseFonts = ['monospace', 'sans-serif', 'serif'];

    //we use m or w because these two characters take up the maximum width.
    // And we use a LLi so that the same matching fonts can get separated
    testString = "mmmmmmmmmmlli";

    //we test using 72px font size, we may use any size. I guess larger the better.
    testSize = '72px';

    h = document.getElementsByTagName("body")[0];

    // create a SPAN in the document to get the width of the text we use to test
    s = document.createElement("span");
    s.style.fontSize = testSize;
    s.innerHTML = testString;
    for (index in baseFonts) {
        //get the default width for the three base fonts
        s.style.fontFamily = baseFonts[index];
        h.appendChild(s);
        defaultWidth[baseFonts[index]] = s.offsetWidth; //width for the default font
        defaultHeight[baseFonts[index]] = s.offsetHeight; //height for the defualt font
        h.removeChild(s);
    }

    detector.detect = function(font) {
        var detected = false, index, matched;
        for (index in baseFonts) {
            s.style.fontFamily = font + ',' + baseFonts[index]; // name of the font along with the base font for fallback.
            h.appendChild(s);
            matched = (s.offsetWidth !== defaultWidth[baseFonts[index]] || s.offsetHeight !== defaultHeight[baseFonts[index]]);
            h.removeChild(s);
            detected = detected || matched;
        }
        return detected;
    };

    return detector;
}());
/*
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
 *
 * Copyright (c) 2009 Sun Microsystems Inc. All Rights Reserved
 *
 * The contents of this file are subject to the terms
 * of the Common Development and Distribution License
 * (the License). You may not use this file except in
 * compliance with the License.
 *
 * You can obtain a copy of the License at
 * https://opensso.dev.java.net/public/CDDLv1.0.html or
 * opensso/legal/CDDLv1.0.txt
 * See the License for the specific language governing
 * permission and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL
 * Header Notice in each file and include the License file
 * at opensso/legal/CDDLv1.0.txt.
 * If applicable, add the following below the CDDL Header,
 * with the fields enclosed by brackets [] replaced by
 * your own identifying information:
 * "Portions Copyrighted [year] [name of copyright owner]"
 *
 */
/*
 * Portions Copyrighted 2013 Syntegrity.
 * Portions Copyrighted 2013-2014 ForgeRock AS.
 */

var collectScreenInfo = function () {
        var screenInfo = {};
        if (screen) {
            if (screen.width) {
                screenInfo.screenWidth = screen.width;
            }

            if (screen.height) {
                screenInfo.screenHeight = screen.height;
            }

            if (screen.pixelDepth) {
                screenInfo.screenColourDepth = screen.pixelDepth;
            }
        } else {
            console.warn("Cannot collect screen information. screen is not defined.");
        }
        return screenInfo;
    },
    collectTimezoneInfo = function () {
        var timezoneInfo =  {}, offset = new Date().getTimezoneOffset();

        if (offset) {
            timezoneInfo.timezone = offset;
        } else {
            console.warn("Cannot collect timezone information. timezone is not defined.");
        }

        return timezoneInfo;
    },
    collectBrowserPluginsInfo = function () {

        if (navigator && navigator.plugins) {
            var pluginsInfo = {}, i, plugins = navigator.plugins;
            pluginsInfo.installedPlugins = "";

            for (i = 0; i < plugins.length; i++) {
                pluginsInfo.installedPlugins = pluginsInfo.installedPlugins + plugins[i].filename + ";";
            }

            return pluginsInfo;
        } else {
            console.warn("Cannot collect browser plugin information. navigator.plugins is not defined.");
            return {};
        }

    },
// Getting geolocation takes some time and is done asynchronously, hence need a callback which is called once geolocation is retrieved.
    collectGeolocationInfo = function (callback) {
        var geolocationInfo = {},
            successCallback = function(position) {
                geolocationInfo.longitude = position.coords.longitude;
                geolocationInfo.latitude = position.coords.latitude;
                callback(geolocationInfo);
            }, errorCallback = function(error) {
                console.warn("Cannot collect geolocation information. " + error.code + ": " + error.message);
                callback(geolocationInfo);
            };
        if (navigator && navigator.geolocation) {
            // NB: If user chooses 'Not now' on Firefox neither callback gets called
            //     https://bugzilla.mozilla.org/show_bug.cgi?id=675533
            navigator.geolocation.getCurrentPosition(successCallback, errorCallback);
        } else {
            console.warn("Cannot collect geolocation information. navigator.geolocation is not defined.");
            callback(geolocationInfo);
        }
    },
    collectBrowserFontsInfo = function () {
        var fontsInfo = {}, i, fontsList = ["cursive","monospace","serif","sans-serif","fantasy","default","Arial","Arial Black",
            "Arial Narrow","Arial Rounded MT Bold","Bookman Old Style","Bradley Hand ITC","Century","Century Gothic",
            "Comic Sans MS","Courier","Courier New","Georgia","Gentium","Impact","King","Lucida Console","Lalit",
            "Modena","Monotype Corsiva","Papyrus","Tahoma","TeX","Times","Times New Roman","Trebuchet MS","Verdana",
            "Verona"];
        fontsInfo.installedFonts = "";

        for (i = 0; i < fontsList.length; i++) {
            if (fontDetector.detect(fontsList[i])) {
                fontsInfo.installedFonts = fontsInfo.installedFonts + fontsList[i] + ";";
            }
        }
        return fontsInfo;
    },
    devicePrint = {};

devicePrint.screen = collectScreenInfo();
devicePrint.timezone = collectTimezoneInfo();
devicePrint.plugins = collectBrowserPluginsInfo();
devicePrint.fonts = collectBrowserFontsInfo();

if (navigator.userAgent) {
    devicePrint.userAgent = navigator.userAgent;
}
if (navigator.appName) {
    devicePrint.appName = navigator.appName;
}
if (navigator.appCodeName) {
    devicePrint.appCodeName = navigator.appCodeName;
}
if (navigator.appVersion) {
    devicePrint.appVersion = navigator.appVersion;
}
if (navigator.appMinorVersion) {
    devicePrint.appMinorVersion = navigator.appMinorVersion;
}
if (navigator.buildID) {
    devicePrint.buildID = navigator.buildID;
}
if (navigator.platform) {
    devicePrint.platform = navigator.platform;
}
if (navigator.cpuClass) {
    devicePrint.cpuClass = navigator.cpuClass;
}
if (navigator.oscpu) {
    devicePrint.oscpu = navigator.oscpu;
}
if (navigator.product) {
    devicePrint.product = navigator.product;
}
if (navigator.productSub) {
    devicePrint.productSub = navigator.productSub;
}
if (navigator.vendor) {
    devicePrint.vendor = navigator.vendor;
}
if (navigator.vendorSub) {
    devicePrint.vendorSub = navigator.vendorSub;
}
if (navigator.language) {
    devicePrint.language = navigator.language;
}
if (navigator.userLanguage) {
    devicePrint.userLanguage = navigator.userLanguage;
}
if (navigator.browserLanguage) {
    devicePrint.browserLanguage = navigator.browserLanguage;
}
if (navigator.systemLanguage) {
    devicePrint.systemLanguage = navigator.systemLanguage;
}

// Attempt to collect geo-location information and return this with the data collected so far.
// Otherwise, if geo-location fails or takes longer than 30 seconds, auto-submit the data collected so far.
autoSubmitDelay = 30000;
output.value = JSON.stringify(devicePrint);
collectGeolocationInfo(function(geolocationInfo) {
    devicePrint.geolocation = geolocationInfo;
    output.value = JSON.stringify(devicePrint);
    submit();
});