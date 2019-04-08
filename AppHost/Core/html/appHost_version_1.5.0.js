!function() {
    window.appHost = {
        version: "1.5.1"
    };
    
    var callbackPool = {};
    var ack_no = 1;
    window.appHost.invoke = function(_action, _data, _callback) {
        var rndKey = 'cbk_' + new Date().getTime();
        var fullParam = {
            action: _action,
            param: _data
        };
        if (_callback) { //如果有回调函数。
            var rndKey = 'cbk_' + ack_no++;
            fullParam.callbackKey = rndKey;
            callbackPool[rndKey] = _callback;
        }

        window.webkit.messageHandlers.kAHScriptHandlerName.postMessage(fullParam)
    }
    var reqs = {};
    window.appHost.on = function(_action, _callback) {
        reqs[_action + ""] = _callback;
    }
    window.appHost.__fire = function(_action, _data) {
        var func = reqs[_action + ""];
        if (typeof func == 'function') {
            func(_data);
        }
    }
    window.appHost.__callback = function(_callbackKey, _param) {
        var func = callbackPool[_callbackKey];
        if (typeof func == 'function') {
            func(_param);
            // 释放,只用一次
            callbackPool[_callbackKey] = nil;
        }
    }
}(window);
