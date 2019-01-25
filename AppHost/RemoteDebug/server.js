window.appHost = {
    invoke: function (action, param) {
        var xhr = new XMLHttpRequest();
        xhr.open('POST', '/command.do', true);
        xhr.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
        xhr.onload = function () {
            console.log(xhr.responseURL); // http://example.com/test
        };

        xhr.send('action=' + action + '&param=' + encodeURI(window.JSON.stringify(param)));
    }
};


window.kLogIndex = 1;
function loop() {
    var xhr = new XMLHttpRequest();
    xhr.open('POST', '/react_log.do', true);
    xhr.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
    xhr.responseType = 'json';
    xhr.onload = function () {
        console.log(xhr.response);
        var json = xhr.response;
        if (json.code == 'OK') {
            var data = json.data;
            if (data) {
                var logs = data.logs;
                if (logs.length > 0) {
                    for (var i = 0; i < logs.length; i++) {
                        var log = window.JSON.parse(logs[i]);
                        var logType = log.type;
                        var logVal = log.value;
                        
                        //  查询所有的接口，显示需要特殊处理下
                        if (logVal.action === 'api_list') {
                            var apis = [];
                            for (var key in logVal.param) {
                                if (logVal.param.hasOwnProperty(key)) {
                                    var response = logVal.param[key];
                                    if (response.length > 0){
                                        apis.push({
                                            type: 'group',
                                            value: key + ' 的方法包括;'
                                        });
                                        for (var k = 0; k < response.length; k++){
                                            apis.push({
                                                type:'api',
                                                value: '  -  ' + response[k]
                                            });
                                        }
                                    }
                                }
                            }
                            addStore({
                                type:'api_list',
                                apis: apis
                            });
                        }else if (logVal.action.indexOf('api_list.') >= 0) {
                            // 特殊处理 API 接口的显示
                            var doc = logVal.param;
                            addStore({
                                type:'api_list_item',
                                doc: doc
                            });
                        } else {
                            // 先显示日志类型，
                            var eleId = 'eid' + window.kLogIndex++;
                            /**
                             * 先初始化一个带 id 的 div，然后在确认渲染成功后，使用 dom 原生的方法，把 renderjson 对象加上去.
                             * 注意 renderjson 对象是带事件的，如果直接渲染为 HTML 会出现丢失事件的情况
                             *  
                             * */ 
                            var preEle = renderjson.set_icons('+', '-').set_show_to_level(2)(logVal);

                            var metaFunc = function(_id, e, d){
                                return function(){
                                    var ele = d.getElementById(_id);
                                    ele.appendChild(e);
                                };
                            };
                            addStore({
                                type:'log',
                                message:logType.toLocaleUpperCase(),
                                eid:eleId
                            }, metaFunc(eleId, preEle, document));

                        }
  
                    }
                }
            }
        }
    };
    xhr.send('');
}

function scrollToBottom() {
    // scroll to bottom
    var output = document.getElementById('output');
    output.scrollTop = output.scrollHeight;
}

function _parseCommand(com){
    if (com == ':testcase') {
        com = "window.appHost.invoke('testcase', {})";
    } else if (com.indexOf(':api_list') >= 0) {
        var args = com.split(' ');
        if (args.length == 1) {
            com = "window.appHost.invoke('api_list', {})";
        } else if (args.length == 2) {
            com = "window.appHost.invoke('api_list', {name:'" + args[1] + "'})";
        } else {
            console.log('参数出错 ' + com);
        }

    }
    return com;
}
// vue
var store = {
    debug: true,
    state: {
        dataSource: [
            {
                type:'welcome',
                message:'欢迎使用 AppHost Remote Debugger'
            }
        ] // 各类的信息，分不同的类型，显示不一样的样式；
    },
    setMessageAction: function(newValue) {
      if (this.debug) console.log('setMessageAction triggered with', newValue);
      this.state.message = newValue;
    },
    clearMessageAction: function () {
      if (this.debug) console.log('clearMessageAction triggered');
      this.state.message = '';
    }
};

function addStore(_obj, _domreadyblock){
    store.state.dataSource.push(_obj);
    Vue.nextTick(function() {
        if(_domreadyblock && typeof _domreadyblock === 'function'){
            _domreadyblock();
        }
        scrollToBottom();
    });
}
// 输入命令和点击按钮区域
Vue.component('command-value', {
    data:function(){
        return {
            command: ':help'
        };
    },
    template:'#command-value-template',
    methods: {
        submit: function(){
            this.$refs.run.click();
        },
        run:function(){
            var com = this.command;
            if (com.length === 0) {
                alert('请输入命令');
                return;
            }

            command.value = '';
            if (com == ':help') {
                addStore({
                    type:'help',
                    message: ''
                });
            } else {
                addStore({
                    type:'command',
                    message: com
                });
                try {
                    var r = window.eval(_parseCommand(com));
                    if (r) {
                        addStore({
                            type:'evalResult',
                            'message': r
                        });
                    }
                } catch (error) {
                    if (error) {
                        addStore({
                            type:'error',
                            message: error.message
                        });
                    }
                }
            }
        }
    }
});

// 执行结果或者服务器推送的结果区域
Vue.component('command-output',{
    data: function(){
        return {
            dataSource: store.state.dataSource
        };
    },
    methods: {

    },
    template:'#command-output-template'
});

document.addEventListener("DOMContentLoaded", function (event) {
    console.log("DOM ready!");
    var app = new Vue({
        el: '#app',
        created: function(){
            console.log('App goes');
        },
        mounted: function(){
            window.setInterval(loop, 2000);
        }
    });
});

function jdb(line) {
    // do a thing, possibly async, then…
    if (window.__bri == line) {
        window.alert('Stop at Debugger;');
    } else {
        console.log('Skip at line ' + line);
    }
}
document.addEventListener("readystatechange", function (event) {
    console.log("readystatechange!" + document.readyState);
    if (document.readyState == 'complete') {
        // jsdebugger
        window.__bri = -1;

        
        var command = document.getElementById('command');
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