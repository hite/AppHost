// 本文件为了替换 self.webView evaluateJavaScript:javaScriptString completionHandler:nil

!(function (window) {
// https://stackoverflow.com/questions/7893776/the-most-accurate-way-to-check-js-objects-type
    window.ah_typeof = function (global) {
        var cache = {};
        return function (obj) {
            var key;
            return obj === null? "null" // null
                : obj === global? "global" // window in browser or global in nodejs
                : (key = typeof obj) !== "object"? key // basic: string, boolean, number, undefined, function
                : obj.nodeType? "DOMElement" // DOM element
                : cache[(key = {}.toString.call(obj))] || // cached. date, regexp, error, object, array, math
                (cache[key] = key.slice(8, -1).toLowerCase()); // get XXXX from [object XXXX], and cache it
        };
    }(window);
    // 
    var safeCopy = function(_origin){
        if (!_origin) return;
        var r = {};
        for (var key in _origin) {
            if (_origin.hasOwnProperty(key)) {
                var val = _origin[key];
                if(val == null) break;

                var objType = window.ah_typeof(val);
                if (['object','array'].indexOf(objType) > -1){
                    r[key] = Object.prototype.toString.call(val);
                } else if('string, boolean, number,date'.indexOf(objType) > -1) {
                    r[key] = _origin[key];
                }
            }
        }
        return r;
    };

    var serialize = function(obj){
        var r = null;
        switch(ah_typeof(obj)){
            case 'null':
            case 'global':
            case 'string':
            case 'boolean':
            case 'number':
            case 'undefined':
            case 'date':
            case 'array':
            //  以上不处理
                r = obj;
            break;
            case 'location':
            case 'window':
                r = safeCopy(obj);
            break;
            case 'regexp':
                r = Object.toString.call(obj);
            break;
            case 'DOMElement':
                r = {
                    nodeType: obj.nodeType,
                    nodeName: obj.nodeName,
                    html: obj.outerHTML
                };
            break;
            default:
                if(typeof obj.toJSON === 'function'){
                    r = obj.toJSON();
                } else {
                    r = 'Unsupported Type: ' + obj;
                }
            
        }
        return r;
    };
    // https://weblogs.asp.net/yuanjian/json-performance-comparison-of-eval-new-function-and-json
    window.ah_eval = function (r) {
        var err = null;

        r = serialize(r);
        if (err == null && r == null){
            return {};
        } else if (err == null && r != null){
            return {'result': r};
        } else if (err != null && r == null){
            return {'err': err};
        } else {
            return {'result': r, 'err': err};
        }
    };
})(this);
