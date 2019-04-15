window.appHost = {
    invoke: function (action, param) {
        var xhr = new XMLHttpRequest();
        xhr.open("POST", "/command.do", true);
        xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
        xhr.onload = function () {
            console.log(xhr.responseURL); // http://example.com/test
        };

        xhr.send(
            "action=" + action + "&param=" + encodeURIComponent(window.JSON.stringify(param))
        );
    }
};

function _renderLogs(logs) {
    if (!logs) return;

    for (var i = 0; i < logs.length; i++) {
        var log = window.JSON.parse(logs[i]);
        var logType = log.type;
        var logVal = log.value;

        //  查询所有的接口，显示需要特殊处理下
        if (logVal.action === "requestToTiming_on_mac"){
            ah_timing(logVal.param);
        } else if (logVal.action === "list") {
            var apis = [];
            for (var key in logVal.param) {
                if (logVal.param.hasOwnProperty(key)) {
                    var response = logVal.param[key];
                    if (response.length > 0) {
                        apis.push({
                            type: "group",
                            value: key + " 的方法包括;"
                        });
                        for (var k = 0; k < response.length; k++) {
                            apis.push({
                                type: "api",
                                value: "  -  " + response[k]
                            });
                        }
                    }
                }
            }
            addStore({
                type: "list",
                apis: apis
            });
        } else if (logVal.action.indexOf("apropos.") >= 0) {
            // 特殊处理 API 接口的显示
            var doc = logVal.param;
            addStore({
                type: "apropos_item",
                doc: doc
            });
        } else if (logVal.action == 'eval') {
            var r = '';
            if (logVal.param){
                r = logVal.param.result || logVal.param.err;
            }
            addStore({
                type: "evalResult",
                message: r
            });
        } else if (logVal.action == 'console.log') {
            addStore({
                type: "console.log",
                message: logVal.param.text
            });
        } else {
            // 先显示日志类型，
            var eleId = "eid" + window.kLogIndex++;
            /**
             * 先初始化一个带 id 的 div，然后在确认渲染成功后，使用 dom 原生的方法，把 renderjson 对象加上去.
             * 注意 renderjson 对象是带事件的，如果直接渲染为 HTML 会出现丢失事件的情况
             *
             * */

            var preEle = renderjson.set_icons("+", "-").set_show_to_level(2)(logVal);

            var metaFunc = function (_id, e, d) {
                return function () {
                    var ele = d.getElementById(_id);
                    ele.appendChild(e);
                };
            };
            addStore(
                {
                    type: "log",
                    message: logType,
                    eid: eleId
                },
                metaFunc(eleId, preEle, document)
            );
        }
    }
}

window.kLogIndex = 1;
function loop() {
    var xhr = new XMLHttpRequest();
    xhr.open("POST", "/react_log.do", true);
    xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    xhr.responseType = "json";
    xhr.onload = function () {
        // console.log(xhr.response);
        var json = xhr.response;
        if (json.code == "OK") {
            var data = json.data;
            var logs = data ? data.logs : [];
            _renderLogs(logs);
        }
    };
    xhr.send("");
}

function scrollToBottom() {
    // scroll to bottom
    var output = document.getElementById("app");
    output.scrollTop = output.scrollHeight;
}

// 如果可以处理，且已经处理完毕，则返回 null
// 无法处理的则抛到外部
function _parseCommand(com) {
    if (com.indexOf(":") == 0) {
        var args;
        if (com == ":testcase") {
            com = "window.appHost.invoke('testcase', {})";
        } else if (com.indexOf(":list") >= 0) {
            com = "window.appHost.invoke('list', {})";
        } else if (com.indexOf(":apropos") >= 0) {
            args = com.split(" ");
            if (args.length == 2) {
                com = "window.appHost.invoke('apropos', {name:'" + args[1] + "'})";
            } else {
                console.log("参数出错 " + com);
                com = null;
            }
        } else if (com.indexOf(":weinre") >= 0) {
            var url = com.replace(':weinre','').trim();
            if (url.length > 0) {
                if (url === "disable") {
                    com = "window.appHost.invoke('weinre', {disabled:true})";
                } else {
                    com = "window.appHost.invoke('weinre', {url:'" + url + "'})";
                }
            } else {
                console.log("参数出错 " + com);
                com = null;
            }
        } else if (com.indexOf(":timing") >= 0) {
            var mobile = com.replace(":timing", "").trim();
            if (mobile.length > 0){
                com = "window.appHost.invoke('timing', {mobile:true})";
            } else {
                com = "window.appHost.invoke('timing', {})";
            }
        } else if (com.indexOf(":eval") >= 0) {
            var code = com.replace(":eval", "").trim();
            if (code.length > 0) {
                var p = window.JSON.stringify({ code: code.trim() });
                com = "window.appHost.invoke('eval', " + p + ")";
            } else {
                console.log("参数出错 " + com);
                com = null;
            }
        } else {
            window.alert("不支持的命令 " + com);
            com = null;
        }
    }

    return com;
}
// vue
var store = {
    debug: true,
    state: {
        dataSource: []
    },
    setMessageAction: function (newValue) {
        if (this.debug) console.log("setMessageAction triggered with", newValue);
        this.state.message = newValue;
    },
    clearMessageAction: function () {
        if (this.debug) console.log("clearMessageAction triggered");
        this.state.message = "";
    }
};

function addStore(_obj, _domreadyblock) {
    store.state.dataSource.push(_obj);
    Vue.nextTick(function () {
        if (_domreadyblock && typeof _domreadyblock === "function") {
            _domreadyblock();
        }
        scrollToBottom();
    });
}
// 输入命令和点击按钮区域
var clientStorage = window.localStorage;
var COMMOND_HISTORY = 'command_history';
var history_header_cursor = clientStorage.length;
var history_search_cursor = history_header_cursor;
var MAX_HISTORY = 100;

function _run_command(com) {
    if (com.length === 0) {
        alert("请输入命令");
        return;
    }
    // 先处理对控制台的控制的命令，然后处理需要获取业务数据的命令
    if (com == ":clear") {
        store.state.dataSource.length = 0;
        com = null;
    } else if (com == ":history") {
        var cm = [];
        var len = clientStorage.length;
        for (var i = len - 1; i >= 0; i--){
            cm.push(clientStorage.getItem(COMMOND_HISTORY + i));
        }
        addStore({
            type: "history",
            data: cm
        });
    } else if (com == ":help") {
        addStore({
            type: "help",
            message: ""
        });
    } else {
        addStore({
            type: "command",
            message: com
        });
        try {
            var newCom = _parseCommand(com);
            if (newCom && newCom.length > 0) {
                var r = window.eval(newCom);
                if (r) {
                    addStore({
                        type: "evalResult",
                        message: r.toString()
                    });
                }
            }
        } catch (error) {
            if (error) {
                addStore({
                    type: "error",
                    message: error.message
                });
            }
        }
    }
}

Vue.component("command-value", {
    data: function () {
        return {
            command: ":help"
        };
    },
    template: "#command-value-template",
    methods: {
        submit: function () {
            this.$refs.run.click();
        },
        history: function(up){
            if (up){
                history_search_cursor--;
            } else {
                history_search_cursor++;
            }
            history_search_cursor = history_search_cursor % MAX_HISTORY;
            history_search_cursor = Math.max(0, history_search_cursor);
            history_search_cursor = Math.min(history_header_cursor, history_search_cursor);
            var n = clientStorage.getItem(COMMOND_HISTORY + history_search_cursor);
            if (n){
                document.getElementById('command').value = n;
                this.command = n;
            }
        },
        run: function () {
            var com = this.command;
            var oldCom = com;

            if(window.ah_env.isMobile){
                com = ':eval ' + com;
            }
            _run_command(com);
            command.value = '';
            this.command = '';
            //            
            clientStorage.setItem(COMMOND_HISTORY + (history_header_cursor++), oldCom);
            history_search_cursor = history_header_cursor;
        }
    }
});

// 执行结果或者服务器推送的结果区域
Vue.component("command-output", {
    data: function () {
        return {
            dataSource: store.state.dataSource
        };
    },
    methods: {
        useHistoryCommand: function(e){
            var ele = e.target;
            var com = ele.dataset.command;
            _run_command(com);
        }
    },
    template: "#command-output-template"
});

document.addEventListener(
    "DOMContentLoaded",
    function (event) {
        console.log("DOM ready!");
        var app = new Vue({
            el: "#app",
            created: function () {
                console.log("App goes");
            },
            mounted: function () {
                window.setInterval(loop, 2000);
            }
        });
    },
    false
);

function jdb(line) {
    // do a thing, possibly async, then…
    if (window.__bri == line) {
        window.alert("Stop at Debugger;");
    } else {
        console.log("Skip at line " + line);
    }
}
document.addEventListener("readystatechange", function (event) {
    console.log("readystatechange!" + document.readyState);
    if (document.readyState == "complete") {
        // jsdebugger
        window.__bri = -1;

        var command = document.getElementById("command");
        // jdb(0);
        // var run = document.getElementById('run');
        // jdb(1);
        // var a = 10;
        // jdb(2)
        // var c = 9;
        // jdb(3)
        // a = a + ~c + 1;
        // jdb(4)
        // console.log(a);
        // jdb(5)

        // run.onclick = function (e) {
        //     var com = command.value; jdb(6);
        //     if (com.length > 0) {
        //         eval(com); jdb(7);
        //     } else {
        //         alert('请输入命令'); jdb(8);
        //     }
        // }
    }
});
