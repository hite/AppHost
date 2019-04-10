window.ah_env = {
    // 表示当前命令行执行的环境，isMobile = true 表示所有的语句是在远端的 webview 里执行的; false 表示是当前浏览器
    isMobile: false
};

Vue.component("tool-panel", {
    data: function () {
        return {
            dataSource: [
                {
                    action: "switch",
                    clsName: "w-tool-item w-tool-switch",
                    title: "点击进入 mobile",
                    text: "Off Mobile"
                },
                {
                    action: "help",
                    clsName: "w-tool-item w-tool-help",
                    title: "look for help",
                    text: "Help"
                },
                {
                    action: "list",
                    clsName: "w-tool-item w-tool-docs",
                    title: "documents for api",
                    text: "Docs"
                },
                {
                    action: "timing",
                    clsName: "w-tool-item w-tool-timing",
                    title: "Audit",
                    text: "Timing"
                }
            ]
        };
    },
    methods: {
        useTool: function (e) {
            var _real_switch_env = function(){
                Vue.set(this.dataSource, 0, {
                    action: "switch",
                    clsName: "w-tool-item w-tool-switch",
                    title: window.ah_env.isMobile ? "点击退出 mobile" : "点击进入 mobile",
                    text: window.ah_env.isMobile ? "On Mobile" : "Off Mobile"
                });
                // 使用原生的方法操作 ele，切换 输入栏处的图标
                document.getElementsByClassName('j-mobile2pc')[0].style = window.ah_env.isMobile ? 'display:block' : 'display:none';
                document.getElementsByClassName('j-pc2mobile')[0].style = window.ah_env.isMobile ? 'display:none' : 'display:block';
                var runBtn = document.getElementById('command');
                if (window.ah_env.isMobile) {
                    runBtn.placeholder = '在这里输入脚本，点击 Run 执行';
                } else {
                    runBtn.placeholder = '输入命令，如. :help';
                }
            }.bind(this);

            var ele = e.target;
            var action = ele.dataset.action;
            switch (action) {
                case "switch":
                    {
                        window.ah_env.isMobile = !window.ah_env.isMobile;
                        _real_switch_env();
                    }
                    break;
                case 'help':
                case 'list':
                case 'timing':
                    {
                        window.ah_env.isMobile = false;
                        _real_switch_env();
                        _run_command(':' + action);
                    }
                    break;
            }
        }
    },
    template: "#tool-panel-template"
});