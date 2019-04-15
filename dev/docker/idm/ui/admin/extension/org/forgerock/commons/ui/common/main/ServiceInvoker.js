"use strict";

/*
 * Copyright 2011-2017 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

define(["jquery", "underscore", "org/forgerock/commons/ui/common/main/AbstractConfigurationAware", "org/forgerock/commons/ui/common/main/ErrorsHandler", "org/forgerock/commons/ui/common/main/EventManager", "org/forgerock/commons/ui/common/main/i18nManager", "org/forgerock/commons/ui/common/util/Constants", "org/forgerock/commons/ui/common/util/detectiOS"], function ($, _, AbstractConfigurationAware, ErrorsHandler, EventManager, i18nManager, Constants, detectiOS) {
    /**
     * @exports org/forgerock/commons/ui/common/main/ServiceInvoker
     */
    var obj = new AbstractConfigurationAware();

    /**
     * Performs a REST service call.
     * <p>
     * If a <tt>dataType</tt> of <tt>"json"</tt> is set on the options, the request has it's <tt>contentType</tt> set to
     * be <tt>"application/json"</tt> automatically.
     * <p>
     * Additional options can also be passed to control behaviour beyond what
     * {@link http://api.jquery.com/jquery.ajax|$.ajax()} is aware of:
     * <code><pre>
     * {
     *     suppressEvents: true // Default "false". Suppresses dispatching of EVENT_START_REST_CALL,
     *                             EVENT_REST_CALL_ERROR and EVENT_END_REST_CALL events.
     * }
     * </code></pre>
     * @param  {Object} options Options that will be passed to {@link http://api.jquery.com/jquery.ajax|$.ajax()}
     * @return {@link http://api.jquery.com/Types/#jqXHR|jqXHR} Return value from call to
     *                          {@link http://api.jquery.com/jquery.ajax|$.ajax()}
     */
    obj.restCall = function (options) {
        var successCallback = options.success,
            errorCallback = options.error,
            hasDataType = options.hasOwnProperty("dataType"),
            isJSONRequest = hasDataType && options.dataType === "json",
            promise = $.Deferred(),
            resolveHandler,
            _rejectHandler,
            ie11 = !!window.MSInputMethodContext && !!document.documentMode;

        resolveHandler = function resolveHandler() {
            promise.resolve.apply(promise, arguments);
        };

        _rejectHandler = function (jqXHR, textStatus, errorThrown) {
            if (!options.suppressEvents) {
                if (jqXHR.getResponseHeader("www-authenticate") && options.retryAttempts < 1) {
                    // The access token may have been updated since the last attempt; update the request to use it.
                    options.headers["Authorization"] = "Bearer " + sessionStorage.getItem("accessToken");
                    options.retryAttempts++;
                    $.ajax(options).then(resolveHandler, _rejectHandler);
                } else {
                    if (errorCallback) {
                        errorCallback(jqXHR);
                    }
                    promise.reject.apply(promise, arguments);
                }
            } else {
                if (errorCallback) {
                    errorCallback(jqXHR);
                }
                promise.reject.apply(promise, arguments);
            }
        };


        /**
         * Logic to cover two scenarios:
         * 1. If we don't have a dataType we default to JSON
         * 2. If the dataType is "json" we ensure the correct value for contentType has been set
         */
        if (!hasDataType || isJSONRequest) {
            options.dataType = "json";
            options.contentType = "application/json";
        }

        obj.applyDefaultHeadersIfNecessary(options, obj.configuration.defaultHeaders);
        
        // Add the access token to all xhr requests before they are sent
        options.headers["Authorization"] = "Bearer " + sessionStorage.getItem("accessToken");

        if (!options.suppressEvents) {
            EventManager.sendEvent(Constants.EVENT_START_REST_CALL, {
                suppressSpinner: options.suppressSpinner
            });
        }

        options.success = function (data, textStatus, jqXHR) {
            if (data && data.error) {
                if (!options.suppressEvents) {
                    EventManager.sendEvent(Constants.EVENT_REST_CALL_ERROR, {
                        data: $.extend({}, data, { type: this.type }),
                        textStatus: textStatus,
                        jqXHR: jqXHR,
                        errorsHandlers: options.errorsHandlers
                    });
                }

                if (errorCallback) {
                    errorCallback(data);
                }
            } else {
                if (!options.suppressEvents) {
                    EventManager.sendEvent(Constants.EVENT_END_REST_CALL, {
                        data: data,
                        textStatus: textStatus,
                        jqXHR: jqXHR
                    });
                }

                if (successCallback) {
                    successCallback(data, jqXHR);
                }
            }
        };

        // The error handling function passed into restCall will be executed
        // (if defined) as part of the rejectHandler above. A provided success
        // handler will execute as normal, because there is no special logic
        // needed around handling successful requests.
        delete options.error;

        options.xhrFields = {
            /**
             * Useful for CORS requests, should we be accessing a remote endpoint.
             * @see http://www.html5rocks.com/en/tutorials/cors/#toc-withcredentials
             */
            withCredentials: true
        };

        /**
         * This is the jQuery default value for this header, but unless manually specified (like so) it won't be
         * included in CORS requests.
         */
        options.headers["X-Requested-With"] = "XMLHttpRequest";

        /**
         * Default to disabled caching for all AJAX requests. Can be overriden in the rare cases when caching AJAX is
         * needed
         */
        if (!_.has(options.headers, "Cache-Control")) {
            options.headers["Cache-Control"] = "no-cache";
        }

        if (!_.has(options.headers, "Accept-Language")) {
            options.headers["Accept-Language"] = i18nManager.lang;
        }

        // Avoids WebKit bug. See OPENAM-9610
        if (_.inRange(detectiOS(), 9, 10)) {
            options.async = false;
        }

        // This fix is needed for IE11. If you make an ajax request at the same time
        // as certain events (like paste) the event can conflict with the ajax request resulting an
        // access denied from the ajax request. Putting the ajax request in a settimeout forces
        // the ajax request to occur at the end of the stack, preventing the access denied error.
        // https://stackoverflow.com/questions/26891783/ie-11-error-access-is-denied-xmlhttprequest
        if (ie11) {
            setTimeout(function () {
                $.ajax(options).then(resolveHandler, _rejectHandler);
            }, 1);
        } else {
            $.ajax(options).then(resolveHandler, _rejectHandler);
        }

        return promise;
    };

    /**
     * Test TODO create test using below formula
     * var x = {headers:{"a": "a"},b:"b"};
     * require("org/forgerock/commons/ui/common/main/ServiceInvoker").applyDefaultHeadersIfNecessary(x, {a:"x",b:"b"});
     * y ={};
     * require("org/forgerock/commons/ui/common/main/ServiceInvoker").applyDefaultHeadersIfNecessary(y, {a:"c",d:"c"});
     */
    obj.applyDefaultHeadersIfNecessary = function (options, defaultHeaders) {
        var oneHeaderName;

        if (!defaultHeaders) {
            return;
        }

        if (!options.headers) {
            options.headers = defaultHeaders;
        } else {
            for (oneHeaderName in defaultHeaders) {
                if (options.headers[oneHeaderName] === undefined) {
                    options.headers[oneHeaderName] = defaultHeaders[oneHeaderName];
                }
            }
        }
    };

    return obj;
});
