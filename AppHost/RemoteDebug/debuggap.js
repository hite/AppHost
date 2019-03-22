/*
 * 	author: vic wang
 */
(function() {
  debuggap = {
    version: '1.0.0'
  }

  var qs = function(q, c) {
    c = c ? c : document;
    return c.querySelector(q);
  };
  var qsa = function(q, c) {
    c = c ? c : document;
    return c.querySelectorAll(q);
  };
  var dg = debuggap;

  // the prefix of css3 property.
  dg.css3Prefix = '-webkit-';

  //self-closed tag
  dg.selfClosing = {
    img: 1,
    hr: 1,
    br: 1,
    area: 1,
    base: 1,
    basefont: 1,
    input: 1,
    link: 1,
    meta: 1,
    command: 1,
    embed: 1,
    keygen: 1,
    wbr: 1,
    param: 1,
    source: 1,
    track: 1,
    col: 1
  };

  //browser type
  dg.browser = 'webkit';
  if (/MSIE|\.NET|IEMobile/i.test(navigator.userAgent)) {
    dg.browser = 'ie';
  }

  //width and height of page.
  dg.size = function() {
    return {
      width: document.documentElement.clientWidth,
      height: document.documentElement.clientHeight
    }
  };

  //extend method
  dg.extend = function() {
    var target = arguments[0] || {},
      i = 1,
      length = arguments.length,
      deep = false,
      options;

    if (target.constructor == Boolean) {
      deep = target;
      target = arguments[1] || {};
      i = 2;
    }

    if (typeof target != "object" && typeof target != "function")
      target = {};

    if (length == 1) {
      target = this;
      i = 0;
    }

    for (; i < length; i++)

      if ((options = arguments[i]) != null)

        for (var name in options) {
          if (target === options[name])
            continue;

          if (deep && options[name] && typeof options[name] == "object" && target[name] && !options[name].nodeType)
            target[name] = psoft.extend(deep, target[name], options[name]);

          else if (options[name] != undefined)
            target[name] = options[name];

        }

    return target;
  };

  //inherit method
  dg.inherit = function(obj) {
    for (var i in obj) {
      if (job[i]) {
        (function(name) {
          var pre = job[name];
          job[name] = function() {
            pre.apply(this, arguments);
            obj[name].apply(this, arguments);
          }
        })(i);
      }
    }
  }

  // deal with the property of node.
  dg.css = function(node, param, fun, time) {
    if (typeof param == 'object') {
      node.length || (node = [node]);
      for (var i = 0; i < node.length; i++) {
        var temp = node[i];
        for (var n in param) {
          if (n in temp.style) {
            temp.style[n] = param[n];
          } else {
            str = ';' + n + ':' + param[n];
            temp.style.cssText += str;
          }
        }
      }
      if (fun) {
        var temp = function() {
          fun(node);
        }
        setTimeout(temp, time);
      }
    } else {
      var style = getComputedStyle(node, null);
      return style.getPropertyValue(param);
    }
  };

  dg.classes = {
    add: function(node, name) {
      var classes = node.className;
      if (!this.have(node, name)) {
        classes = classes ? (classes + " " + name) : name.toString();
        node.setAttribute('class', classes);
      }
    },
    remove: function(node, name) {
      if (name) {
        var classes = node.className;
        classes = classes.replace(name, '').replace(/^\s+|\s+$/g, "");
        node.setAttribute('class', classes);
      } else {
        node.className = '';
      }
    },
    have: function(node, name) {
      var reg = new RegExp("\\b" + name + "\\b");
      var classes = node.className;
      return reg.exec(classes);
    }
  };


  //draw scale
  dg.scale = function(color) {
    var flag;
    if (flag = qs('#debuggapScale')) {
      flag.parentNode.removeChild(flag);
    }
    if (color) {
      conf.scaleColor = color;
    } else {
      color = conf.scaleColor;
    }
    var arr = [
      ['top, transparent 4px, ' + color + ' 5px', '10px 5px', '100%', '10px'],
      ['top, transparent 24px, ' + color + ' 25px', '20px 25px', '100%', '20px'],
      ['left, transparent 4px, ' + color + ' 5px', '5px 10px', '10px', '100%'],
      ['left, transparent 24px, ' + color + ' 25px', '25px 20px', '20px', '100%']
    ];
    flag = document.createElement('div');
    flag.id = 'debuggapScale';
    dg.classes.add(flag, 'dg-scale');
    for (var i = 0; i < 4; i++) {
      var div = document.createElement('div');
      var childArr = arr[i];
      var style = 'background:' + dg.css3Prefix + 'linear-gradient(' + childArr[0] + ');background-size:' + childArr[1] + ';height:' + childArr[2] + ';width:' + childArr[3];
      style += ';position:absolute;left:0px;top:0px;z-index:999;';
      div.setAttribute('style', style);
      flag.appendChild(div);
    }
    qs('#debuggapRoot').appendChild(flag);
  };

  //configure
  dg.conf = {
    scaleColor: '#cccccc',
    lineColor: '#cc6600'
  };
  var conf = {};

  //draw the nodes
  dg.draw = {
    drawLi: function(obj) {
      var li = document.createElement('li');
      li.className = "dg-node";
      //deal with the comment
      if (obj.nodeType == 8) {
        var value = obj.nodeValue;
        value = value.replace(/\</g, '&lt;').replace(/\>/g, '&gt;');
        li.innerHTML = '<pre class="pre"><span class="com">&lt;!--' + value + '--&gt;</span></pre>';
        return li;
      } else if (obj.nodeType == 3) {
        //deal with the text node.
        li.innerHTML = '<pre class="pre">' + obj.nodeValue + '</pre>';
        return li;
      } else if (obj.nodeType == 10) {
        //deal with the doctype
        li.style.color = '#ccc';
        li.innerHTML = '&lt;!DOCTYPE ' + obj.name + " " + obj.publicId + " " + obj.systemId + '&gt;';
        return li;
      }
      var tag = obj.tagName.toLowerCase();
      var str = '<span class="tag">&lt;' + tag + '</span>';
      var attrs = obj.attributes;
      var dir = null;
      //get the attributes of node.
      for (var i = 0; i < attrs.length; i++) {
        str += ' <span class="attr">' + attrs[i].name + '=</span>' + '<span class="val">"' + attrs[i].value + '"</span>';
      }
      if (dg.selfClosing[tag]) {
        str += '<span class="tag">/&gt;</span>';
      } else {
        str += '<span class="tag">&gt;</span>';
        if (obj.childNodes.length) {
          str += '...';
          //create the direction element
          dir = document.createElement('span');
          dir.className = 'dg-right';
          //create the tapping selction.
          var tap = document.createElement('span');
          tap.className = 'dg-tap';
        }
        str += '<span class="tag">&lt;/' + tag + '&gt;</span>';
      }

      li.innerHTML = str;
      if (dir) {
        li.appendChild(dir);
        li.appendChild(tap);
      }
      return li;
    },
    getRelation: function(obj) {
      var parent = obj.parentNode;
      var result = [];
      var current = obj;
      do {
        //clean the nodes
        var ch = [];
        var tmp = dg.filterChildNodes(parent, [1, 3, 8]);
        for (var i = 0; i < tmp.length; i++) {
          if (tmp[i].className != 'dg-child') {
            ch.push(tmp[i]);
          }
        }
        // remember the position in the siblings
        for (var y = 0; y < ch.length; y++) {

          if (ch[y] == current) {
            break;
          }
        }
        result.unshift(y);
        if (parent.tagName.toLowerCase() == 'ul' && parent.id == 'debuggapTree') {
          break;
        }
        current = parent.parentNode;
        do {
          current = current.previousSibling;
        } while (current.nodeType != 1);

        parent = current.parentNode;

      } while (1);
      return result;
    },
    findRelation: function(obj) {
      var root = document;
      var tmp = dg.filterChildNodes(root, [1, 3, 8, 10]);
      var rt;
      do {
        var ch = [];
        for (var i = 0; i < tmp.length; i++) {
          if (tmp[i].id != 'debuggapRoot') {
            ch.push(tmp[i]);
          }
        }
        var pos = obj.shift();
        rt = ch[pos];
        tmp = dg.filterChildNodes(rt, [1, 3, 8, 10]);
      } while (obj.length);
      return rt;
    },
    doAction: function(node) {
      var value = {};
      if (!dg.classes.have(node, 'dg-rotate')) {

        var li = this.add(node.parentNode);
      } else {

        var li = this.del(node);
      }
      delete node;
    },
    add: function(ele) {
      var value = ele.innerHTML;
      value = value.replace(/\.\.\.(.*?)<\/span>/, '');
      ele.innerHTML = value;
      var relation = this.getRelation(ele);
      var result = this.findRelation(relation);
      var ch = dg.filterChildNodes(result, [1, 3, 8]);
      var li = document.createElement('li');
      li.className = 'dg-child';
      var ul = document.createElement('ul');
      for (var i = 0; i < ch.length; i++) {
        if (ch[i].id != 'debuggapRoot') {
          ul.appendChild(this.drawLi(ch[i]));
        }
      }
      li.appendChild(ul);
      //add the self-close tag
      var close = document.createElement('li');
      close.className = 'dg-child';
      close.innerHTML = '<span class="tag">&lt;/' + result.tagName.toLowerCase() + '&gt;</span>';
      ele.parentNode.insertBefore(close, ele.nextSibling);
      //add the children
      ele.parentNode.insertBefore(li, close);
      var node = qs('.dg-right', ele);
      dg.classes.add(node, 'dg-rotate');
      return ele;
    },
    del: function(node) {
      var li = node.parentNode;
      var value = li.innerHTML;
      var tag = value.match(/&lt;(.+?)<\/span>/)[1];
      value = value.replace(/&gt;<\/span>/, '&gt;<\/span>...<span class="tag">&lt;/' + tag + '&gt;</span>');
      li.innerHTML = value;
      var ele = li.nextSibling;
      ele.parentNode.removeChild(ele);
      li.parentNode.removeChild(li.nextSibling);
      var node = qs('.dg-right', li);
      dg.classes.remove(node, 'dg-rotate');
      //redraw the line style
      if (dg.classes.have(li, 'line-wh')) {
        dg.map.treeToEle(li);
      }
      return li;
    }
  };

  //utility
  dg.extend({
    indexArray: function(ele, arr) {
      for (var i = 0; i < arr.length; i++) {
        if (arr[i] == ele) {
          return i;
        }
      }
      return -1;
    },
    inArray: function(ele, arr) {
      return (this.indexArray(ele, arr) != -1) ? true : false;
    },
    isArray: function(obj) {
      return toString.call(obj) === "[object Array]";
    },
    each: function(object, callback, args) {
      if (object.length == undefined) {
        for (var name in object)
          if (callback.call(object[name], name, object[name], args) === false)
            break;
      } else {
        for (var i = 0, length = object.length; i < length; i++)
          if (callback.call(object[i], i, object[i], args) === false)
            break;
      }
    },
    position: function(node) {
      var left = document.body.scrollLeft,
        top = document.body.scrollTop;
      var w = node.clientWidth;
      var h = node.clientHeight;
      var ele = node;
      while (ele && ele != document.body) {
        left += ele.offsetLeft;
        top += ele.offsetTop;
        ele = ele.offsetParent;
      }
      return {
        left: left,
        top: top,
        width: w,
        height: h
      };
    },
    max: function(a, b) {
      return a > b ? a : b;
    },
    min: function(a, b) {
      return a > b ? b : a;
    },
    preName: function(name) {
      return dg.css3Prefix + name;
    },
    trim: function(str) {
      return str.replace(/^\s+|\s+$/g, "");
    },
    createEle: function(tag, attrs, con) {
      var tag = document.createElement(tag);
      for (var i in attrs) {
        tag.setAttribute(i, attrs[i]);
      }
      if (con) {
        tag.innerHTML = con;
      }
      return tag;
    },
    isFunction: function(func) {
      return typeof func == "function";
    },
    filterChildNodes: function(ele, type) {
      type = type ? type : [1, 3, 8];
      var rt = [];
      var ch = ele.childNodes;
      for (var i = 0; i < ch.length; i++) {
        if (dg.inArray(ch[i].nodeType, type)) {
          if (ch[i].nodeType == 3 && dg.trim(ch[i].nodeValue) == "") {
            continue;
          }
          rt.push(ch[i]);
        }
      }
      return rt;
    },
    ajax: function(filePath, fun, data) {
      var xml = new XMLHttpRequest();
      var method = data ? 'POST' : 'GET';
      xml.open(method, filePath, true, '', '');
      xml.setRequestHeader("Accept", "text/plain, */*");
      xml.setRequestHeader("innerUse", true);
      xml.innerUse = true;
      xml.onreadystatechange = function() {
        if (xml && xml.readyState == 4) {
          fun(xml);
          xml = null;
          delete(xml);
        }
      }
      xml.send(data ? data : null);
    },
    bind: function(obj, func) {
      if (typeof func == 'string') {
        func = obj[func];
      }
      return function() {
        func.apply(obj, arguments);
      }
    }
  });

  //map the node element
  dg.map = {
    treeToEle: function(node) {
      //remove the map if the map exists.
      this.preShadowNode && this.removeMap(this.preShadowNode);
      //remember the shadow node.
      this.preShadowNode = node;

      var relation = dg.draw.getRelation(node);
      var result = dg.draw.findRelation(relation);
      this.drawShadow(result);

      dg.classes.add(node, 'line-wh');
      dg.each(qsa('span', node), function() {
        dg.classes.add(this, 'font-wh');
      });
    },
    eleToTree: function(node) {
      //get the ralation in the real node tree according to the variable.
      var relation = dg.map.getRelation(node);

      if (job.socketReady()) {
        job.doLeafStructure(relation.join(','));
        this.drawShadow(node);
        dg.scale();
      } else {
        //show the tree 
        dg.doc.trigger(qsa('#debuggapBlock .dg-leaf')[0], 'tap');

        var currentNode = qs('#debuggapTree');
        //based on the ralation, expand the tree.
        for (var i = 0; i < relation.length - 1; i++) {
          var v = relation[i];
          var li = qsa('li', currentNode)[v];
          dg.draw.add(li);
          currentNode = li.nextSibling;
        }
        //draw the shadow.
        li = qsa('li', currentNode)[relation[i]];
        dg.map.treeToEle(li);
        //this.drawShadow(node);
      }
    },
    getRelation: function(node) {
      var rt = [],
        tmp, ch;
      var ele = node;
      do {
        if (!ele.parentNode) {
          break;
        }
        ch = dg.filterChildNodes(ele.parentNode, [1, 3, 8, 10]);
        // remember the position in the siblings
        for (var y = 0; y < ch.length; y++) {
          if (ch[y] == ele) {
            break;
          }
        }
        rt.unshift(y);
        ele = ele.parentNode;
      } while (ele && ele.nodeType != 9);

      return rt;
    },
    removeMap: function(node) {

      dg.classes.remove(node, 'line-wh');
      dg.each(qsa('span', node), function() {
        dg.classes.remove(this, 'font-wh');
      });
      // remove the shadow
      var dom = qs('#debuggapShadow');
      dom && debuggapNode.removeChild(dom);
      //remove the line
      dg.each(qsa('.debuggapLine'), function() {
        debuggapNode.removeChild(this);
      });

      this.preShadowNode = null;

    },
    drawShadow: function(node) {
      //tap any content,remove the shadow.
      dg.doc.bind(document, 'taps', function(e) {
        //dg.doc.trigger( qs('#debuggapBlock .dg-center'),'tap' );
        dg.each(qsa('#debuggapTree,#debuggapScale,#debuggapShadow,#debuggapConfig,.debuggapLine'), function() {
          debuggapNode.removeChild(this);
        });
        dg.doc.unbind(document);
        e.preventDefault();
        e.stopPropagation();
      });

      var dom = qs('#debuggapShadow');
      dom && debuggapNode.removeChild(dom);

      var rect = node.getBoundingClientRect();
      var list = ['padding', 'border', 'margin'];
      var d = ['left', 'right', 'top', 'bottom'];
      var rt = {};
      for (var i = 0; i < list.length; i++) {
        rt[list[i]] = [];
        var end = '';
        if (list[i] == 'border') {
          end = "-width";
        }
        for (var j = 0; j < d.length; j++) {
          var name = list[i] + '-' + d[j] + end;
          rt[list[i]].push(parseInt(dg.css(node, name)));
        }
      }

      var pos = {
        left: rect.left + document.body.scrollLeft,
        top: rect.top + document.body.scrollTop,
        width: rect.width - rt['border'][0] - rt['border'][1],
        height: rect.height - rt['border'][2] - rt['border'][3]
      };

      pos.left = Math.ceil(pos.left - rt['margin'][0]);
      pos.top = Math.ceil(pos.top - rt['margin'][2]);
      pos.width = dg.max(pos.width - rt['padding'][0] - rt['padding'][1], 0);
      pos.height = dg.max(pos.height - rt['padding'][2] - rt['padding'][3], 0);
      //create the shadow accordingly
      var div = document.createElement('div');
      dg.css(div, {
        width: pos.width + 'px',
        height: pos.height + 'px',
        opacity: 0.5,
        'background-color': '#3879d9'
      });

      //sum value of margin and border
      for (var i = 0; i < 4; i++) {
        rt['margin'][i] += rt['border'][i];
      }
      //remove the border property.
      list.splice(1, 1);
      for (var j = 0; j < list.length; j++) {
        var str = list[j];
        if (rt[str][0] + rt[str][1] + rt[str][2] + rt[str][3] != 0) {
          var tmp = document.createElement('div');
          var value = {
            'opacity': 0.8
          };
          for (var i = 0; i < d.length; i++) {
            var name = 'border-' + d[i];
            value[name] = rt[str][i] + 'px solid ' + this['borderColor'][str];
          }
          dg.css(tmp, value);
          tmp.appendChild(div);
          div = tmp;
        }
      }
      dg.css(div, {
        position: 'absolute',
        left: pos.left + 'px',
        top: pos.top + 'px'
      });
      div.id = 'debuggapShadow';
      var first = debuggapNode.childNodes[0];
      debuggapNode.insertBefore(div, first);
      //draw the line around the shadow
      var w = pos.width + rt['padding'][0] + rt['padding'][1] + rt['margin'][0] + rt['margin'][1];
      var h = pos.height + rt['padding'][2] + rt['padding'][3] + rt['margin'][2] + rt['margin'][3];
      this.drawLine(pos.left, pos.top, w, h);
    },
    drawLine: function(a, b, w, h) {
      dg.each(qsa('.debuggapLine'), function() {
        debuggapNode.removeChild(this);
      });
      if (w == 0 || h == 0) {
        return;
      }

      var width = dg.size().width;
      var height = dg.size().height;
      var lines = [
        [a, 0, 1, b],
        [a + w - 1, 0, 1, b],
        [a, b + h, 1, height - b - h],
        [a + w - 1, b + h - 1, 1, height - b - h],
        [0, b, a, 1],
        [a + w, b, width - a - w, 1],
        [0, b + h - 1, a, 1],
        [a + w, b + h - 1, width - a - w, 1]
      ];
      var flag = document.createDocumentFragment();
      var color = conf.lineColor;
      for (var i = 0; i < lines.length; i++) {
        var v = lines[i];
        var d = document.createElement('div');
        dg.css(d, {
          left: v[0] + 'px',
          top: v[1] + 'px',
          width: v[2] + 'px',
          height: v[3] + 'px',
          position: 'absolute',
          'background-color': color
        });
        dg.classes.add(d, 'debuggapLine');
        flag.appendChild(d);
      }
      var first = debuggapNode.childNodes[0];
      debuggapNode.insertBefore(flag, first);
    },
    noMap: {
      html: 1,
      head: 1,
      script: 1,
      style: 1,
      meta: 1,
      title: 1,
      option: 1
    },
    borderColor: {
      padding: '#329406',
      border: '#dd903f',
      margin: '#c56c0e'
    },
    preShadowNode: null
  };

  //debug console	
  dg.console = {
    log: function() {
      var node = this.createLine();
      if (!dg.inArray(this.focus, ['all', 'log'])) {
        dg.css(node, {
          'display': 'none'
        });
      }
      dg.classes.add(node, 'dg-l');
      qsa('td', node)[1].innerHTML = this.concatArg(arguments);
    },
    warn: function() {
      var node = this.createLine();
      if (!dg.inArray(this.focus, ['all', 'warn'])) {
        dg.css(node, {
          'display': 'none'
        });
      }
      dg.classes.add(node, 'dg-w');
      qsa('td', node)[0].innerHTML = '<div class="dg-warn"></div><div class="dg-type-con">!</div>';
      qsa('td', node)[1].innerHTML = this.concatArg(arguments);
    },
    error: function() {
      var node = this.createLine();
      if (!dg.inArray(this.focus, ['all', 'error'])) {
        dg.css(node, {
          'display': 'none'
        });
      }
      dg.classes.add(node, 'dg-e');
      qsa('td', node)[0].innerHTML = '<div class="dg-error"></div><div class="dg-type-con">x</div>';
      qsa('td', node)[1].innerHTML = "<span style='color:red'>" + this.concatArg(arguments) + '</span>';
    },
    concatArg: function(obj) {
      var str = '';
      for (var i = 0, len = obj.length; i < len; i++) {
        str += (' ' + obj[i]);
      }
      return str;
    },
    tryCatch: function(str) {
      if (this.history[0] != str) {
        this.history.unshift(str);
      }
      var node = this.createLine(str);
      try {
        if (/(for|while)/.exec(str)) {
          str = "return new Function(\"" + str + "\")()";
        } else {
          str = "return " + str;
        }
        var value = new Function(str)();
        if (!value) {
          value += '';
        } else if (typeof value == 'string') {
          value = '<span style="white-space:pre;color:#cb4416;">' + value.replace(/\>/g, '&gt;').replace(/\</g, '&lt;') + '</span>';
        } else if (typeof value == 'function') {
          value = '<span style="white-space:pre">' + value + '</span>';
        }
        this.log(value);
      } catch (e) {
        this.error(e.name + ': ' + e.message);
      };
    },
    createLine: function(str) {
      var node = document.createElement('tr');
      node.innerHTML = '<td></td><td></td>';
      dg.each(qsa('td', node), function(i) {
        if (i == 1 && str) {
          this.innerHTML = '<span style="color:blue;">' + str + '</span>';
        } else {
          this.innerHTML = '';
        }
      });
      dg.classes.add(qsa('td', node)[0], 'dg-type');
      dg.classes.add(qsa('td', node)[1], 'dg-con');
      qs('table', qs('#debuggapConsole .dg-console')).appendChild(node);
      return node;
    },
    history: [],
    index: -1,
    up: function() {
      this.index++;
      if (this.index < this.history.length) {
        qs('#debuggapInput').value = this.history[this.index];
      } else {
        this.index--;
      }
    },
    down: function() {
      this.index--;
      if (this.index < 0) {
        qs('#debuggapInput').value = '';
        this.index = -1;
      } else {
        qs('#debuggapInput').value = this.history[this.index];
      }
    },
    go: function() {
      var dom = qs('#debuggapInput');
      if (!dom.value) {
        return;
      }
      this.tryCatch(dom.value);
      this.index = -1;
      dom.value = '';
    },
    clean: function() {
      var p = qs('.dg-console', qs('#debuggapConsole'));
      var trs = qsa('tr', p);
      dg.each(trs, function() {
        this.parentNode.removeChild(this);
      });
    },
    focus: 'all',
    filter: function(obj) {
      var value = obj.innerHTML;
      if (value.toLowerCase() == 'clean') {
        this.clean();
        return true;
      }
      this.focus = value.toLowerCase();
      //set the focus.
      dg.each(qsa('span', obj.parentNode), function() {
        if (this == obj) {
          dg.classes.add(this, 'dg-console-focus');
        } else {
          dg.classes.remove(this, 'dg-console-focus');
        }
      });
      var c = value.toLowerCase()[0];
      var p = qs('.dg-console', qs('#debuggapConsole'));
      if (c == 'a') {
        var rt = {
          'display': 'table-row'
        };
      } else {
        var rt = {
          'display': 'none'
        }
      }
      //initialize the setting
      dg.each(qsa('.dg-l,.dg-e,.dg-w', p), function() {
        dg.css(this, rt);
      });
      if (c != 'a') {
        var str = '.dg-' + c;
        dg.each(qsa(str), function() {
          dg.css(this, {
            'display': 'table-row'
          });
        });
      }
    },
    overwrite: function() {
      var list = ['log', 'warn', 'error'];
      for (var i = 0; i < list.length; i++) {
        var tmp = console[list[i]];
        (function(fun, type) {
          console[type] = function() {
            fun.apply(this, arguments);
            if (qs('#debuggapConsole')) {
              dg.console[type].apply(dg.console, arguments);
            } else {
              dg.console.cacheConsoleMessage(type, arguments)
            }
            //send to the remote client
            for (var j = 0; j < arguments.length; j++) {
              send(type + "Cmd" + ":" + job._transformCmd(arguments[j]));
            }
          };
        })(tmp, list[i]);
      }
      list = null;
      tmp = null;
      delete list;
      delete tmp;
    },
    __cache: {},
    cacheConsoleMessage: function(type, args) {
      if (!dg.console.__cache[type]) {
        dg.console.__cache[type] = []
      }
      dg.console.__cache[type].push(args)
    },
    showCachedMessage: function() {
      var obj = dg.console.__cache
      for (var i in obj) {
        var arr = obj[i]
        for (var j = 0; j < arr.length; j++) {
          dg.console[i].apply(dg.console, arr[j]);
        }
      }
      dg.console.__cache = {}
    }
  };
  dg.console.overwrite();

  // event handle
  dg.event = {
    eventIndex: 1,
    inWrap: function(pos, touch) {
      var maxX = pos.left + pos.width;
      var maxY = pos.top + pos.height;
      var pX = touch.pageX;
      var pY = touch.pageY;
      if (pX > pos.left && pY > pos.top && pX < maxX && pY < maxY) {
        return true;
      }
    },
    register: function(regNode) {
      if (!(this instanceof arguments.callee)) {
        return true;
      }
      var topNode = regNode.parentNode;
      var stopTap = 0;
      var directTap = 0;
      var originalX = 0,
        originalY = 0;
      var translate = '';

      var events = {};
      this.bind = function(node, type, fun) {
        var event;
        if (typeof node == 'string') {
          if (event = events[node]) {
            event[type] = fun;
          } else {
            event = {};
            event[type] = fun;
            events[node] = event;
          }
        } else if (node.dgEventIndex) {
          event = events[node.dgEventIndex];
          if (event) {
            event[type] = fun;
          } else {
            event = {};
            event[type] = fun;
            events[node.dgEventIndex] = event;
          }
        } else {
          node.dgEventIndex = dg.event.eventIndex++;
          event = {};
          event[type] = fun;
          events[node.dgEventIndex] = event;
        }
      }

      this.unbind = function(node) {
        if (node.dgEventIndex && events[node.dgEventIndex]) {
          events[node.dgEventIndex] = null;
          delete events[node.dgEventIndex];
        }
      }

      this.trigger = function(node, type) {
        var index = node.dgEventIndex;
        var event;
        if (event = events[index]) {
          event[type].call(node, null);
        }
      }

      this.destroy = function() {
        events = null;
        regNode.removeEventListener('touchmove', move, false);
        regNode.removeEventListener('touchend', end, false);
        regNode.removeEventListener('touchstart', start, false);
        move = null;
        end = null;
        start = null;
      }

      var start = function(e) {
        var touch = e.touches && e.touches[0] || e;
        var ele = touch.target;
        directTap = 0;
        while (ele != topNode && ele) {
          var index = ele.dgEventIndex;
          var s = events[index];
          if (s && s.scroll) {
            var t = s.scroll;
            stopTap = 0;
            directTap = 1;
            t.dgOx = touch.pageX;
            t.dgOy = touch.pageY;
            dg.css(t, {
              '-webkit-transition': ''
            });
            var translate = t.style['WebkitTransform'] ? t.style['WebkitTransform'] : 'translate(0px,0px)';
            var arr = translate.match(/translate\(([^\)]*)\)/)[1].split(',');
            //console.log('luo:'+arr.join('-'));
            t.dgX = parseInt(arr[0]);
            t.dgY = parseInt(arr[1]);
            return true;
          } else if (s && s.move) {
            stopTap = 0;
          }
          if (s && s.taps) {
            if (s.taps.call(ele, e)) {
              return true;
            }
          }
          ele = ele.parentNode;
        }
      };

      var move = function(e) {
        var touch = e.touches[0];
        var ele = touch.target;
        while (ele != topNode && ele) {
          var index = ele.dgEventIndex;
          var s = events[index];
          if (s && s.scroll) {
            var t = s.scroll;
            stopTap = 1;
            if (Math.abs(touch.pageY - t.dgOy) > Math.abs(touch.pageX - t.dgOx)) {
              var value = 'translate(' + t.dgX + 'px,' + (touch.pageY - t.dgOy + t.dgY) + 'px) ';
            } else {
              var value = 'translate(' + (touch.pageX - t.dgOx + t.dgX) + 'px,' + t.dgY + 'px) ';
            }
            t.style['WebkitTransform'] = value;

            e.preventDefault();
            return true;
          } else if (s && s.move) {
            stopTap = 1;
            e.preventDefault();
            e.stopPropagation();
            if (s.move.call(ele, e)) {
              return true;
            }
          }

          ele = ele.parentNode;
        }
      };

      var end = function(e) {
        var touch = e.changedTouches[0];
        var ele = touch.target;
        while (ele != topNode && ele) {
          var index = ele.dgEventIndex;
          var tagName = (ele.tagName || '').toLowerCase();
          var s = events[index] ? events[index] : events[tagName];
          if (s && s.tap && !stopTap) {
            if (ele.nodeType == 1) {
              var p = dg.position(ele);
            } else {
              directTap = 1;
            }
            if (directTap || dg.event.inWrap(p, touch)) {
              if (s.tap.call(ele, e)) {
                return true;
              }
            }
          }
          if (s && s.scroll && stopTap) {
            var t = s.scroll;
            stopTap = 0;
            var translate = t.style['WebkitTransform'] ? t.style['WebkitTransform'] : 'translate(0px,0px)';
            var arr = translate.match(/translate\(([^\)]*)\)/)[1].split(',');

            t.dgX = parseInt(arr[0]);
            t.dgY = parseInt(arr[1]);
            var maxY = dg.max(t.scrollHeight - parseInt(dg.css(t.parentNode, 'height')), 0);
            var maxX = dg.max(t.scrollWidth - parseInt(dg.css(t.parentNode, 'width')), 0);

            var x = '',
              y = '';
            var changed = 0;
            if (t.dgY > 0) {
              y = '0px';
              changed = 1;
            } else if (Math.abs(t.dgY) > maxY) {
              y = '-' + maxY + 'px';
              changed = 1;
            }
            if (t.dgX > 0) {
              x = '0px';
              changed = 1;
            } else if (Math.abs(t.dgX) > maxX) {
              x = '-' + maxX + 'px';
              changed = 1;
            }

            if (changed) {
              x || (x = t.dgX + 'px');
              y || (y = t.dgY + 'px');

              var value = 'translate(' + x + ',' + y + ')';
              dg.css(t, {
                '-webkit-transition': '-webkit-transform 0.5s',
                '-webkit-transform': value
              });
            }
            return true;
          }
          ele = ele.parentNode;
        }
      };

      regNode.addEventListener('touchmove', move, false);
      regNode.addEventListener('touchend', end, false);
      regNode.addEventListener(dg.browser == "ie" ? 'mousedown' : 'touchstart', start, false);
    }
  };

  /*
   * socket for no websocket
   */

  function ScriptSocket(conf) {
    //init url according to host and port
    this.url = 'http://' + conf.host + ':' + (parseInt(conf.port) + 1) + '/scriptSocket';
    this.readyState = 0;

    //start to load
    this.getSocketData();
    var self = this;
    window.onbeforeunload = function() {
      try {
        self.closeSocket();
      } catch (e) {}
    }
  }
  ScriptSocket.prototype = {
    tryMaxTimes: 1,
    currentTimes: 0,
    readyState: 0,
    timeout: 10,
    getSocketData: function() {
      var script = document.createElement('script');
      script.src = (this.readyState == 0 ? this.url + '/init' : this.url) + "?_d=" + new Date().getTime();
      script.id = 'socket_script';
      script.onload = dg.bind(this, 'success');
      script.onerror = dg.bind(this, 'error');
      document.head.appendChild(script);
    },
    closeSocket: function() {
      var script = document.createElement('script');
      script.src = this.url + '/close' + "?_d=" + new Date().getTime();
      document.head.appendChild(script);
    },
    send: function(data) {
      dg.ajax(this.url, function() {}, data);
    },
    success: function() {
      this._finish();
      setTimeout(dg.bind(this, 'getSocketData'), this.timeout);
    },
    error: function() {
      this._finish();
      if (this.currentTimes++ != this.tryMaxTimes) {
        setTimeout(dg.bind(this, 'getSocketData'), this.timeout);
      } else {
        this.onclose && this.onclose();
      }
    },
    _finish: function() {
      document.head.removeChild(document.getElementById('socket_script'));
    },
    close: function() {}
  }

  //API for script socket
  dg.scriptSocket = {
    handShake: function() {
      if (socket) {
        socket.readyState = 1;
        socket.onopen();
      }
    },
    handle: function(data) {
      socket && socket.onmessage({
        data: data
      });
    }
  }

  /*
   * specific function for different module
   */
  //get css property
  function calculateCss(a) {

    //split the css text and get the contributing css
    function splitCSS(input) {
      // Separate input by commas
      // var match = input.match(/[a-zA-Z0-9_-]+\,[a-zA-Z0-9_-]+/);
      // if( match ){
      // 	match = match[0];
      // 	var pre = input.replace(match,'');
      // 	selectors = match.split(',');
      // 	for( var i=0;i<selectors.length;i++){
      // 		selectors[i] = pre+selectors[i];
      // 	}
      // }else{
      var selectors = input.split(',');
      // }
      return selectors;
    }

    function _calculateStyleRule(a, rule) {
      var result = null;
      if (a.matches(rule.selectorText)) {
        var arr = splitCSS(rule.selectorText),
          matchSelector = rule.selectorText;
        for (var j = 0; j < arr.length; j++) {
          if (a.matches(arr[j])) {
            matchSelector = arr[j];
            break;
          }
        }
        result = {
          css: rule.cssText,
          selectors: rule.selectorText,
          selector: matchSelector
        };
      }
      return result;
    }

    function getClassProperty(a) {
      var sheets = document.styleSheets,
        o = [];
      a.matches = a.matches || a.webkitMatchesSelector || a.mozMatchesSelector || a.msMatchesSelector || a.oMatchesSelector;
      var rules, mediaText;
      for (var sheetIndex = 0, sheetLen = sheets.length; sheetIndex < sheetLen; sheetIndex++) {
        rules = sheets[sheetIndex].cssRules || sheets[sheetIndex].rules;
        mediaText = sheets[sheetIndex].media && sheets[sheetIndex].media.mediaText;
        if (!mediaText || mediaText == 'all') {
          mediaText = '';
        }

        //if rules is empty or css doesn't match media query,then return;
        if (!rules || mediaText && !window.matchMedia(mediaText).matches) {
          continue;
        }
        var href = sheets[sheetIndex].href || (location.pathname + location.search);
        var obj = {},
          rule;
        for (var ruleIndex = 0, ruleLen = rules.length; ruleIndex < ruleLen; ruleIndex++) {
          try {
            rule = rules[ruleIndex];
            if (rule.type == 1) {
              //here is stylerule
              obj = _calculateStyleRule(a, rule);
              if (obj) {
                obj.href = href;
                obj.sheetIndex = sheetIndex;
                obj.cssRuleIndex = [ruleIndex];
                //if this css rule is matched by media query,so add the media query string.
                mediaText && (obj.mediaText = 'media="' + mediaText + '"');
                o.push(obj);
              }

            } else if (rule.type == 4) {
              //here is MediaRule
              var mediaTextExtra = rule.media && rule.media.mediaText || '';
              if (mediaTextExtra && window.matchMedia(mediaTextExtra).matches) {
                var mediaCssRules = rule.cssRules || rule.rules;
                if (mediaCssRules) {
                  for (var mediaRuleIndex = 0, mediaRuleLen = mediaCssRules.length; mediaRuleIndex < mediaRuleLen; mediaRuleIndex++) {
                    obj = _calculateStyleRule(a, mediaCssRules[mediaRuleIndex]);
                    if (obj) {
                      obj.href = href;
                      obj.sheetIndex = sheetIndex;
                      obj.cssRuleIndex = [ruleIndex, mediaRuleIndex];
                      obj.mediaText = '@media ' + mediaTextExtra;
                      o.push(obj);
                    }
                  }
                }
              }
            } else if (rule.type == 3) {
              //this is the import way.

            }
          } catch (e) {}
        }
      }

      return o;
    }

    function getStyleProperty(a) {
      var v = a.getAttribute('style');
      return v ? v : '';
    }

    return {
      _class: getClassProperty(a),
      _style: getStyleProperty(a)
    }
  }

  //overwrite http(s)
  (function() {
    var xmlObj = {};

    function dealUrl(url) {
      var str = url;
      if (url.slice(0, 4) != 'http') {
        if (url.slice(0, 1) == '/') {
          str = location.protocol + '//' + location.host + url;
        } else if (url.slice(0, 2) == './') {
          str = (location.protocol + '//' + location.host + location.pathname).replace(/\/.[^\/]*$/, '/') + url.slice(2);
        }
      }
      return str;
    }

    var _open = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function(method, url, async) {
      try {
        var uniqueId = new Date().getTime() * 1000 + Math.floor(Math.random() * 1000);
        var str = dealUrl(url);
        if (str.slice(0, 4) == 'http' || str.slice(0, 4) == 'file') {
          this.uniqueId = uniqueId;
          xmlObj[uniqueId] = {
            method: method,
            url: str,
            header: {}
          }
        }
      } catch (e) {}
      _open.apply(this, arguments);
    }

    var _setRequestHeader = XMLHttpRequest.prototype.setRequestHeader;
    XMLHttpRequest.prototype.setRequestHeader = function(key, value) {
      if (this.uniqueId) {
        xmlObj[this.uniqueId].header[key] = value;
      }
      _setRequestHeader.apply(this, arguments);
    }

    var _send = XMLHttpRequest.prototype.send;
    XMLHttpRequest.prototype.send = function(value) {
      //tag that it's XHR.
      this.setRequestHeader("XHR", true);
      if (this.uniqueId) {
        if (this.innerUse) {
          xmlObj[this.uniqueId] = null;
          delete xmlObj[this.uniqueId];
          _send.apply(this, arguments);
          return;
        }
        xmlObj[this.uniqueId].body = value;

        if (xmlObj[this.uniqueId].url.slice(0, 4) == 'http') {
          var _location = xmlObj[this.uniqueId].url.match(/([^:]+):\/\/([^\/\#\?]+)([^?#]*)([^#]*)(.*)/);
          var host = _location[2].split(':')[0];
          var port = _location[2].split(':')[1] ? _location[2].split(':')[1] : '';
          var obj = {
            method: xmlObj[this.uniqueId].method,
            id: this.uniqueId,
            requestHeaders: xmlObj[this.uniqueId].header,
            httpVersion: 'HTTP/1.1',
            'location': {
              protocol: _location[1],
              host: host,
              port: port,
              hostname: _location[2],
              hash: _location[5],
              search: _location[4],
              pathname: _location[3],
              href: _location[0]
            }
          };
          if (value) {
            obj.payload = value;
          }
          send('initRequest:' + JSON.stringify(obj));
        }

        var startTime = new Date().getTime();
        var self = this;
        var isExecuted = false;

        function callback() {
          if (isExecuted) {
            return;
          }
          isExecuted = true;
          var responseHeaders, responseText;
          try {
            responseHeaders = self.getAllResponseHeaders();
            responseText = self.responseText;
          } catch (e) {
            responseHeaders = '';
            responseText = '';
          }
          if (xmlObj[self.uniqueId].url.slice(0, 4) == 'http') {
            var arr = responseHeaders.split('\r\n');
            responseHeaders = {};
            for (var i = 0, temp; i < arr.length; i++) {
              temp = arr[i];
              if (temp) {
                temp = temp.split(':');
                responseHeaders[temp[0]] = temp[1];
              }
            }

            var obj = {
              host: location.host,
              times: new Date().getTime() - startTime,
              size: responseText.length,
              responseHeaders: responseHeaders,
              data: responseText,
              id: self.uniqueId,
              statusCode: self.status
            }
            send('resultRequest:' + JSON.stringify(obj));
          }
        }

        var id = setInterval(function() {
          if (self.readyState == 4) {
            clearInterval(id);
            callback();
            xmlObj[self.uniqueId] = null;
            delete xmlObj[self.uniqueId];
          }
        }, 5);

        function checkReadystatechange() {
          if (self.onreadystatechange) {
            clearInterval(readyId);
            var _callback = self.onreadystatechange;
            self.onreadystatechange = function() {
              if (self.readyState == 4) {
                callback();
              }
              _callback && _callback();
            };
          }
        }
        var readyId = setInterval(function() {
          checkReadystatechange();
        }, 0);

        checkReadystatechange();

        _send.apply(self, arguments);
      }
    }
  })();

  //add the initialized component.
  dg.init = {
    setting: function() {

    },
    addWrap: function() {
      if (debuggapNode = qs('#debuggapRoot')) {
        return;
      }
      var d = document.createElement('div');
      d.id = 'debuggapRoot';
      document.body.appendChild(d);
      debuggapNode = d;
      //init other components
      dg.init.addStyle();
      dg.init.addConsole();
      dg.init.addBlock();
      //if browser is ie,so hidden the blue spot
      if (dg.browser == 'ie') {
        dg.css(qs('#debuggapBlock'), {
          display: 'none'
        });
      }
    },
    addStyle: function() {
      var s = document.createElement('style');
      s.innerHTML = '' +
        'body{-webkit-text-size-adjust:100%}' +
        '#debuggapRoot input{font-size:14px;-webkit-appearance:none;}' +
        '#debuggapRoot .dg-block{white-space:nowrap;margin: 0px;padding: 20px;}' +
        '#debuggapRoot td{font-family: arial,sans-serif;letter-spacing: 1px;}' +

        '#debuggapRoot .dg-scale{}' +

        '#debuggapRoot li{list-style:none;padding-left:15px;position:relative;font-size:15px;font-family:arial,sans-serif;line-height:18px;text-align:left;}' +
        '#debuggapRoot ul{list-style:none;padding-left:0px;margin:0px;}' +
        'span.dg-down{display:inline-block;border-left:5px solid transparent;border-right:5px solid transparent;border-top:10px solid #515151;width:0px;height:0px;position:absolute;left:0px;top:3px;}' +
        'span.dg-right{-webkit-transition:-webkit-transform 0.5s;transition:transform 0.5s;display:inline-block;border-top:5px solid transparent;border-bottom:5px solid transparent;border-left:10px solid #515151;width:0px;height:0px;position:absolute;left:0px;top:3px;}' +
        'span.dg-tap{height:18px;padding:0px 25px;left:-30px;position:absolute;}' +
        'span.dg-rotate{-webkit-transform:rotate(90deg);transform:rotate(90deg);}' +

        '#debuggapRoot .tag{color:#a5129f;}' +
        '#debuggapRoot .attr{color:#994500}' +
        '#debuggapRoot .val{color:#1a1a7e;}' +
        '#debuggapRoot .com{color:#236e25;}' +
        '#debuggapRoot .pre{margin:0px;padding:0px;}' +
        '#debuggapRoot .font-wh{color:#fff;}' +
        '#debuggapRoot .line-wh{color:#fff;background-color:#3879d9;}' +

        '#debuggapTree {position:absolute;}' +


        '.debuggapFull {background-color:rgba(255,255,255,0.5);position:fixed;left:0px;top:0px;right:0px;bottom:0px;z-index:999;overflow:hidden;}' +
        '.debuggapFull0 {background-color:rgba(255,255,255,1);position:fixed;left:0px;top:0px;right:0px;bottom:0px;z-index:999;overflow:hidden;}' +


        '#debuggapRoot .dg-out{background-color: transparent;position: fixed;z-index: 999;top: 20px;right: 20px;border: 2px solid #00abe3;border-radius: 30px;width: 30px;height: 30px;box-sizing: content-box;}' +
        '#debuggapRoot .dg-inner{width:20px;height: 20px;background: #ccc;margin: 5px;border-radius: 20px;background-color: #00abe3;}' +
        '#debuggapConsole{display:none;padding:10px;margin:0px;}' +
        '#debuggapConsole .dg-console{overflow:hidden;border-top:1px solid #ccc;margin-top:2px;}' +
        '#debuggapConsole .dg-console tr{display:table-row}' +
        '#debuggapInput {width:100%;line-height:16px;padding:2px;margin:0px;border:1px solid #ccc;outline-style:none;}' +
        '#debuggapConsole .dg-up{border-left:8px solid transparent;border-bottom:16px solid #515151;border-right:8px solid transparent;width:0px;height:0px;position:absolute;left:0px;top:7px;}' +
        '#debuggapConsole .dg-go{border-top:8px solid transparent;border-bottom:8px solid transparent;border-left:16px solid #515151;width:0px;height:0px;position:absolute;right:0px;top:2px;}' +
        '#debuggapConsole .dg-down{border-top:16px solid #515151;border-right:8px solid transparent;border-left:8px solid transparent;width:0px;height:0px;position:absolute;left:0px;top:7px;}' +
        '#debuggapConsole .dg-upP{width:20px;height:25px;position:absolute;left:0px;top:0px;}' +
        '#debuggapConsole .dg-downP{width:20px;height:25px;position:absolute;left:25px;top:0px;}' +
        '#debuggapConsole .dg-goP{width:30px;height:20px;position:absolute;right:0px;top:0px;}' +
        '#debuggapConsole .dg-type{width:20px;height:16px;text-align:center;position:relative;}' +
        '#debuggapConsole .dg-con{border-bottom:1px solid #ccc;font-size:11px ! important;word-break:break-all;}' +
        '#debuggapConsole .dg-error{border:6px solid #d80c15;border-radius:6px;width:0px;height:0px;position:absolute;left:0px;top:1px;}' +
        '#debuggapConsole .dg-type-con{width:10px;height:10px;position:absolute;left:1px;top:1px;color:#fff;line-height:10px;font-size:14px;}' +
        '#debuggapConsole .dg-warn{border-left:6px solid transparent;border-bottom:12px solid #f4bd00;border-right:6px solid transparent;width:0px;height:0px;position:absolute;left:0px;top:1px;}' +
        '#debuggapConsole .dg-console-info{padding:0px 5px;color:#fff;background-color:#a8a8a8;border-radius:10px;margin-right:5px;font-size:14px;}' +
        '#debuggapConsole .dg-console-focus{background-color:rgb(0,171,227);}' +

        '#debuggapConfig {padding:10px;margin:0px;}' +
        '#debuggapConfig .dg-conf-bts{height:30px;overflow:hidden;}' +
        '#debuggapConfig .dg-conf-left{border-radius:5px;float:left;background-color:rgb(0,171,227);color:#fff;border:0px}' +
        '#debuggapConfig .dg-conf-right{border-radius:5px;float:right;background-color:rgb(0,171,227);color:#fff;border:0px;}' +

        '#debuggapBlock {}' +
        '#debuggapBlock .dg-leaf{width:70px;height:70px;border-radius:30px;text-align:center;line-height:70px;color:#fff;margin:1px;float:left;background-color:rgba(0,171,227,0.7);}' +
        '#debuggapBlock .dg-flower{width:144px;height:144px;position:fixed;z-index:999;left:50%;top:50%;margin-left:-72px;margin-top:-72px;opacity:0;display:none;-webkit-transition:opacity 0.5s;}' +
        '#debuggapBlock .dg-center{width:50px;height:50px;position:absolute;left:47px;top:47px;border-radius:50px;text-align:center;line-height:50px;color:#fff;margin:1px;float:left;background-color:rgba(0,171,227,1);}';

      debuggapNode.appendChild(s);
    },
    addBlock: function() {
      var d = document.createElement('div');
      d.id = 'debuggapBlock';
      d.innerHTML = '<div id="debuggapScrim" class="debuggapFull" style="display:none;"></div>' +
        '<div class="dg-flower" class="dg-flower">' +
        '<div class="dg-leaf" style="border-top-left-radius:0px;">Nodes</div>' +
        '<div class="dg-leaf" style="border-top-right-radius:0px;">Inspect</div>' +
        '<div class="dg-leaf" style="border-bottom-left-radius:0px;">Config</div>' +
        '<div class="dg-leaf" style="border-bottom-right-radius:0px;" >Console</div>' +
        '<div class="dg-center">Close</div></div>' +
        '<div class="dg-out"><div class="dg-inner"></div></div>';
      debuggapNode.appendChild(d);
    },
    addConsole: function() {
      var d = document.createElement('div');
      d.id = 'debuggapConsole';
      d.innerHTML = '<table border=0 cellpadding="0" cellspacing="0" width=100%>' +
        '<tr><td><input type="txt" id="debuggapInput"/></td><td> <div style="position:relative;width:25px;height:22px;"><div class="dg-goP"><div class="dg-go"></div></div></div></td></tr>' +
        '<tr><td colspan=2 ><div style="height:25px;width:100%;position:relative;">' +
        '<div class="dg-upP"><div class="dg-up"></div></div>' +
        '<div class="dg-downP"><div class="dg-down"></div></div>' +
        '<div style="position:absolute;right:0px;top: 7px;"><span class="dg-console-info dg-console-focus">All</span><span class="dg-console-info">Error</span><span class="dg-console-info">Warn</span><span class="dg-console-info">Log</span><span class="dg-console-info">Clean</span> </div></div></td></tr></table>' +
        '<div class="dg-console">' +
        '<table border=0 cellpadding="0" cellspacing="0" width=100%></table></div>';
      debuggapNode.appendChild(d);
    },
    showTree: function() {
      // draw tha basic tree Node.
      var d = document.createElement('ul');
      d.id = 'debuggapTree';
      dg.classes.add(d, 'dg-block');

      for (var i = 0; i < document.childNodes.length; i++) {
        var rt = debuggap.draw.drawLi(document.childNodes[i]);
        d.appendChild(rt);
      }

      debuggapNode.appendChild(d);

      dg.scale();
      dg.classes.add(qs('#debuggapRoot'), 'debuggapFull');
      dg.css(qs('#debuggapTree'), {
        'min-width': debuggap.size.width + 'px',
        'min-height': debuggap.size.height + 'px'
      });

    },
    destroyTree: function() {
      debuggapNode.removeChild(qs('#debuggapTree'));
      debuggapNode.removeChild(qs('#debuggapScale'));
      dg.classes.remove(debuggapNode, 'debuggapFull');
    },
    showConfig: function() {
      if (!qs('#debuggapConfig')) {
        var d = document.createElement('div');
        d.id = 'debuggapConfig';
        d.innerHTML = '<table width="100%" border=0><caption>Config Setting</caption>' +
          '<tr><td>scale color:</td><td><input type="txt" id="scaleColor"/></td></tr>' +
          '<tr><td>line color:</td><td><input type="txt" id="lineColor"/></td></tr>' +
          //'<tr><td>socket ip:</td><td><input type="txt" id="host"/></td></tr>'+
          '</table>' +
          '<div class="dg-conf-bts"><input class="dg-conf-left" type="button" value="reset"/><input class="dg-conf-right"  type="button" value="modify"/></div>' +
          '<hr/>click the following button to connect to remote DebugGap<br/><div class="dg-socket-bts"><b>Server</b> : <input type="txt" id="dgSocketHost" style="width:100px"> : <input type="txt" id="dgSocketPort" style="width:50px"> <input class="dg-conf-right" id="dgConnect" type="button" value="Connect"/></div>';
        debuggapNode.appendChild(d);
        for (var i in conf) {
          qs('#' + i) && (qs('#' + i).value = conf[i]);
        }
      }

    },
    daemon: function() {
      var count = 0;
      var h = setInterval(function() {
        qs('#debuggapRoot') || dg.init.addWrap();
        if (++count >= 10) {
          dg.start();
          clearInterval(h);
        }
      }, 200);
    },
    reconnect: function() {
      var rt = dg._getCurrentAddr();
      if (rt && rt.length == 2) {
        localStorage.host = rt[0];
        localStorage.port = rt[1];
        localStorage.protocal = 'websocket';
        localStorage.name = 'debuggap_client';
        localStorage.expired = new Date().getTime() + 1000 * 60 * 60;
      }
      if (dg.browser == 'ie' && rt.length != 2) {
        alert('Please include debuggap.js with remote address in IE.\nsuch as:\n<script src="debuggap.js?192.168.1.4:11111"></script>');
        return;
      }

      if (localStorage.expired && (new Date().getTime() < localStorage.expired)) {
        dg.extend(dg.conf, {
          host: localStorage.host,
          port: localStorage.port,
          protocal: localStorage.protocal,
          name: localStorage.name
        });
        dg.initSocket(dg.conf);
      }
    }
  };

  dg.ready = function() {
    debuggap.extend(conf, dg.conf);
    //dg.init.setting();
    dg.init.addWrap();
    //initialize the daemon for runing the debuggap
    dg.init.daemon();
    //re-connect websocket
    dg.init.reconnect();
  }


  dg.start = function() {

    // register the tap event for map functionality.
    var doc = new dg.event.register(document.body);
    dg.doc = doc;

    doc.bind(qs('#debuggapBlock .dg-out'), 'tap', function() {
      //clean the map functionality
      doc.unbind(document);
      var dom = qs('#debuggapBlock .dg-flower');
      if (dg.css(dom, 'opacity') == 0) {
        dg.css(qs('#debuggapScrim'), {
          display: 'block'
        });
        dg.css(qs('.dg-out'), {
          display: 'none'
        });
        dg.css(dom, {
          opacity: 1,
          display: 'block'
        });
      } else {
        dg.css(dom, {
          opacity: 0
        }, function(dom) {
          dg.css(dom, {
            display: 'none'
          });
        }, 500);
      }

      return true;
    });

    doc.bind(qs('#debuggapBlock .dg-out'), 'move', function(e) {
      var target = e.touches[0];
      var x = target.pageX - document.body.scrollLeft,
        y = target.pageY - document.body.scrollTop;
      var mX = dg.size().width - 40;
      var mY = dg.size().height - 40;

      if (x < 10) {
        x = 10;
      } else if (x > mX) {
        x = mX;
      }
      if (y < 10) {
        y = 10;
      } else if (y > mY) {
        y = mY;
      }

      dg.css(this, {
        top: y + 'px',
        left: x + 'px'
      });
      e.preventDefault()
      e.stopPropagation()
      return true;
    });

    //register the debuggapRoot event
    //var root = new dg.event.register( qs('#debuggapRoot') );
    //dg.root = root;

    //bind the arrows event
    doc.bind('span', 'tap', function() {
      if (dg.classes.have(this, 'dg-tap')) {
        var ele = qs('.dg-right', this.parentNode);
        dg.draw.doAction(ele);
        return true;
      } else if (dg.classes.have(this, 'dg-console-info')) {
        dg.console.filter(this);
        return true;
      }
    });
    //bind the map tree node event;
    doc.bind('li', 'tap', function() {
      if (dg.classes.have(this, 'dg-node')) {
        var value = this.innerHTML;
        var tag = value.match(/&lt;(.*?)<\/span>/)[1];
        if (!dg.map.noMap[tag]) {
          if (dg.classes.have(this, 'line-wh')) {
            dg.map.removeMap(this);
          } else {
            dg.map.treeToEle(this);
          }
        }
        return true;
      }
    });

    //bind the config button;
    doc.bind('input', 'tap', function() {
      if (this.parentNode && this.parentNode.className == 'dg-conf-bts') {
        var value = this.value;
        if (value == 'reset') {
          for (var i in conf) {
            if (qs('#' + i)) {
              conf[i] = qs('#' + i).value = dg.conf[i];
            }
          }
        } else {
          for (var i in conf) {
            if (qs('#' + i)) {
              conf[i] = qs('#' + i).value;
            }
          }
          //dg.initSocket(conf);
        }
        return true;
      } else if (this.parentNode && this.parentNode.className == 'dg-socket-bts' && this.type == 'button') {
        //extend the config
        dg.extend(dg.conf, {
          host: qs('#dgSocketHost').value,
          port: qs('#dgSocketPort').value,
          protocal: 'websocket',
          name: 'debuggap_client'
        });
        localStorage.host = dg.conf.host;
        localStorage.port = dg.conf.port;
        localStorage.protocal = dg.conf.protocal;
        localStorage.name = dg.conf.name;
        localStorage.expired = new Date().getTime() + 1000 * 60 * 60;
        this.value = 'Connecting';
        dg.initSocket(dg.conf);

      }
    });

    doc.bind(qs('#debuggapScrim'), 'tap', function(e) {
      dg.css(this, {
        display: 'none'
      });
      dg.css(qs('#debuggapBlock .dg-flower'), {
        opacity: 0
      }, function(dom) {
        dg.css(dom, {
          display: 'none'
        });
      }, 500);
      dg.css(qs('.dg-out'), {
        display: 'block'
      });
      return true;
    });

    //for finder functionality.
    doc.bind(qsa('#debuggapBlock .dg-leaf')[0], 'tap', function(e) {
      doc.trigger(qs('#debuggapBlock .dg-center'), 'tap');
      dg.init.showTree();
      doc.bind(qs('#debuggapRoot'), 'scroll', qs('#debuggapTree'));
      return true;
    });
    //for inspect functionality.
    doc.bind(qsa('#debuggapBlock .dg-leaf')[1], 'tap', function(e) {
      doc.trigger(qs('#debuggapBlock .dg-center'), 'tap');
      doc.bind(qs('#debuggapRoot'), 'scroll', null);

      doc.bind(document, 'taps', function(e) {
        doc.unbind(document);
        var ele = e.changedTouches[0].target;
        //except for the spot
        if (!dg.inArray(ele.className, ['dg-inner', 'dg-out'])) {
          dg.map.eleToTree(ele);
        }
        e.preventDefault();
      });

      e && e.preventDefault();
      e && e.stopPropagation();
      return true;
    });
    //for config functionality.
    doc.bind(qsa('#debuggapBlock .dg-leaf')[2], 'tap', function(e) {
      doc.trigger(qs('#debuggapBlock .dg-center'), 'tap');
      dg.classes.add(qs('#debuggapRoot'), 'debuggapFull0');
      dg.init.showConfig();
      //doc.bind( qs('#debuggapRoot'),'scroll',qs('#debuggapConsole .dg-console table'));

      //get the host and port
      var callback = function(str) {
        try {
          str = JSON.parse(str);
          str = str.split(':');
          //set the value to input box
          qs('#dgSocketHost').value = str[0];
          qs('#dgSocketPort').value = str[1];
        } catch (e) {
          if (localStorage.host) {
            qs('#dgSocketHost').value = localStorage.host;
            qs('#dgSocketPort').value = localStorage.port;
          }
        }
      }

      callback('');
      return true;
    });
    //for console functionality.
    doc.bind(qsa('#debuggapBlock .dg-leaf')[3], 'tap', function(e) {
      // show cache message
      dg.console.showCachedMessage();
      doc.trigger(qs('#debuggapBlock .dg-center'), 'tap');
      dg.css(qs('#debuggapConsole'), {
        'display': 'block'
      });
      dg.classes.add(qs('#debuggapRoot'), 'debuggapFull0');
      doc.bind(qs('#debuggapRoot'), 'scroll', qs('#debuggapConsole .dg-console table'));
      dg.css(qs('#debuggapConsole .dg-console'), {
        'height': (dg.size().height - 65) + 'px'
      });
      return true;
    });
    //for center button.
    doc.bind(qs('#debuggapBlock .dg-center'), 'tap', function(e) {
      doc.trigger(qs('#debuggapScrim'), 'tap');
      dg.each(qsa('#debuggapTree,#debuggapScale,#debuggapShadow,#debuggapConfig,.debuggapLine'), function() {
        debuggapNode.removeChild(this);
      });
      dg.css(qs('#debuggapConsole'), {
        'display': 'none'
      });
      dg.classes.remove(debuggapNode);
      return true;
    });

    //deal with the arrow button in the console page.
    qs('#debuggapInput').addEventListener('keypress', function(e) {
      if (e.which == 13 || e.keyCode == 13) {
        dg.console.go();
      }
    }, false);

    doc.bind(qs('#debuggapConsole .dg-upP'), 'tap', function(e) {
      dg.console.up();
    });

    doc.bind(qs('#debuggapConsole .dg-goP'), 'tap', function(e) {
      dg.console.go();
    });

    doc.bind(qs('#debuggapConsole .dg-downP'), 'tap', function(e) {
      dg.console.down();
    });

  };

  /*----- start for remote debug -----*/

  //functions for communication 
  var job = {
    remoteClientReady: false,
    socketReady: function() {
      return socket && socket.readyState == 1 && job.remoteClientReady;
    },
    doReady: function() {
      console.log('--------------------------------------------------  starts  --------------------------------------------------');
    },
    //initialization
    doInit: function() {
      //get know that the remote client is ready.
      this.remoteClientReady = true;
      //reset the resource variables
      this.preLocalStorage = "";
      this.preSessionStorage = "";
      this.preCookie = "";
      //send the content of dom to the remote debug containner
      var str = "";
      str += dg.indexArray(document.body.parentNode, dg.filterChildNodes(document, [1, 3, 8, 10])) + ",";
      str += dg.indexArray(document.body, dg.filterChildNodes(document.body.parentNode, [1, 3, 8, 10]));

      this.doAllStructure(str);

      //send the userAgent
      send("deviceInfo:" + navigator.userAgent);
    },
    doAllStructure: function(s) {
      var rt;
      rt = job._getStructure(s);
      send("allStructure:" + JSON.stringify(rt));
    },
    doLeafStructure: function(s) {
      var rt;
      var lastCommaPos = s.lastIndexOf(',');
      var lastChar = s.substr(lastCommaPos + 1);
      s = s.substr(0, lastCommaPos);
      rt = job._getStructure(s);
      send("leafStructure:" + lastChar + ";" + JSON.stringify(rt));
    },
    doGetChildren: function(s) {
      var arr = s.split(','),
        i;
      var rt = job._getStructure(s);
      while (arr.length) {
        i = arr.shift();
        rt = rt[i].c;
      }
      send("addChildren:" + s + ";" + JSON.stringify(rt));
    },
    doGetChildrenV2: function(s) {
      //this function will replace doGetChildren function future
      var timestamp = s.slice(0, 13);
      s = s.slice(14);
      var arr = s == '' ? [] : s.split(','),
        i;
      var rt = job._getStructure(s);
      while (arr.length) {
        i = arr.shift();
        rt = rt[i].c;
      }
      send("childrenList:" + timestamp + ";" + s + ";" + JSON.stringify(rt));
    },
    _getStructure: function(s) {
      var arr = s == '' ? [] : s.split(",");
      var root = document;
      var rt = [],
        ch, obj;
      var rootRt = rt;

      while (arr.length) {
        var ch = dg.filterChildNodes(root, [1, 3, 8, 10]);
        var index = parseInt(arr.shift());

        for (var i = 0; i < ch.length; i++) {
          if (ch[i].id == "debuggapRoot") {
            ch.splice(i, 1);
            i--;
            continue;
          }
          var tmp = this._getTagAndAttr(ch[i]);
          rt.push(tmp);
          if (i == index) {
            root = ch[index];
          }
        }
        rt = rt[index].c;
      }
      ch = dg.filterChildNodes(root, [1, 3, 8, 10]);
      for (var i = 0, j = 0; i < ch.length; i++) {
        if (ch[i].id == "debuggapRoot") {
          continue;
        }
        var tmp = this._getTagAndAttr(ch[i]);
        tmp && rt.push(tmp);
      }
      return rootRt;
    },
    _getTagAndAttr: function(ele) {
      var obj = {
        t: ele.nodeName.toLowerCase(),
        c: ele.childNodes.length > 0 ? [] : false
      };

      if (ele.nodeType == 1) {
        obj._dg_t = obj.t;
        if (obj.c && ele.childNodes.length == 1 && ele.childNodes[0].nodeType == 3 && ele.childNodes[0].nodeValue.length < 20) {
          //cs means 'content of children'. if the content is short, so directly return the content;
          obj.cs = ele.childNodes[0].nodeValue;
        }
        var attrs = ele.attributes;
        for (var i = 0; i < attrs.length; i++) {
          if (!obj['a']) {
            obj['a'] = {};
          }
          obj['a'][attrs[i].name] = attrs[i].value;
        }
      } else if (ele.nodeType == 10) {
        obj.s = "<!DOCTYPE " + ele.name + " " + ele.publicId + " " + ele.systemId + ">";
        delete obj.t;
      } else {
        obj.s = ele.nodeValue;
        obj._dg_t = obj.t;
      }
      return obj;
    },
    //get the file content according to file
    doFile: function(filePath) {
      setTimeout(function() {
        dg.ajax(filePath, function(xml) {
          send("fileCon:" + filePath + "_dg_" + xml.responseText);
        });
      }, 100);
    },
    //get command result
    doCmd: function(cmd) {
      try {
        var value = new Function("return " + cmd)();
        value = this._transformCmd(value);
        send("cmdResult:" + value);
      } catch (e) {
        var value = e.name + ': ' + e.message;
        console.error(value);
      };
    },
    _transformCmd: function(value) {
      if (value && dg.inArray(value.nodeType, [1, 3, 8, 9])) {
        var relation = dg.map.getRelation(value);
        value = job._getTagAndAttr(value);
        value.relation = relation;
        value = JSON.stringify(value);
      } else if (Object.prototype.toString.call(value) == '[object Array]') {
        try {
          value = JSON.stringify(value);
        } catch (e) {
          value = this._objectToString(value);
          value = JSON.stringify(value);
        }
      } else if (Object.prototype.toString.call(value) == '[object Object]') {
        value = this._objectToString(value);
        value = JSON.stringify(value);
      }
      return value;
    },
    _objectToString: function(obj) {
      var keys = Object.keys(obj);
      var rt = {},
        key;
      if (obj.length) {
        rt = [];
      }
      for (var i = 0, len = keys.length; i < len; i++) {
        key = keys[i];
        if (obj[key] && dg.inArray(obj[key].nodeType, [1, 3, 8, 9])) {
          var relation = dg.map.getRelation(obj[key]);
          var value = job._getTagAndAttr(obj[key]);
          value.relation = relation;
          rt[key] = {
            v: obj[key].toString(),
            element: value
          };
        } else if (obj[key] && typeof obj[key] == 'object' && Object.keys(obj[key]).length) {
          rt[key] = arguments.callee(obj[key]);
        } else if (typeof obj[key] == 'function') {
          rt[key] = {
            v: obj[key].toString().match(/[^\n{]+/)[0] + '{...}',
            tag: 'func'
          };
        } else if (Object.prototype.toString.call(obj[key]) == '[object RegExp]') {
          rt[key] = {
            v: obj[key].toString(),
            tag: 'reg'
          };
        } else {
          rt[key] = obj[key];
        }
      }
      return rt;
    },
    doFileTree: function() {
      //set the file pre
      this._doFileStart(location.href.replace(location.hash, ''));
      //set the file value
      var s = document.scripts;
      for (var i = 0; i < s.length; i++) {
        if (s[i].src && s[i].src.substr(0, 16) != 'chrome-extension')
          this._doFile(s[i].src);
      }
      var s = document.styleSheets;
      for (var i = 0; i < s.length; i++) {
        if (s[i].href)
          this._doFile(s[i].href);
      }
      //send the files
      var con = [this._sPre, this._sTitle, this._sFiles];
      send('fileTree:' + JSON.stringify(con));
    },
    _doFile: function(file) {
      //console.log(file);
      file = file.replace(this._sPre, "");
      file = file.split("/");
      var arr = this._sFiles;
      if (file.length == 1) {
        arr.push(file[0]);
      } else {
        for (var i = 0; i < file.length - 1; i++) {
          var dirIndex = file[i];
          var arrLen = arr.length;
          var hasDir = false;
          for (var j = 0; j < arrLen; j++) {
            if (typeof arr[j] != 'string' && arr[j][dirIndex]) {
              arr = arr[j][dirIndex];
              hasDir = true;
              break;
            }
          }
          if (!hasDir) {
            var subFile = file.slice(i, -1);
            arr = this._sCreateTree(arr, subFile);
            break;
          }
        }
        arr.push(file[file.length - 1]);
      }
      arr.sort(function(a, b) {
        if (a > b) return 1;
        else return -1;
      });
    },
    _sCreateTree: function(arr, subFile) {
      for (var i = 0; i < subFile.length; i++) {
        var tmp = {};
        tmp[subFile[i]] = [];
        var len = arr.push(tmp);
        var arrTemp = arr;
        arr = arr[len - 1][subFile[i]];
        arrTemp.sort(function(a, b) {
          var aStr = typeof a == "string";
          var bStr = typeof b == "string";
          if (aStr && bStr) {
            if (a > b) return -1;
            else return 1;
          } else if (aStr) {
            return 1;
          } else if (bStr) {
            return -1;
          } else {
            if (Object.keys(a)[0] > Object.keys(b)[0]) return -1;
            else return 1;
          }
        });
      }
      return arr;
    },
    _doFileStart: function(data) {
      this._sPre = data.substring(0, data.lastIndexOf('/') + 1);
      this._sFiles = [];
      this._sTitle = data.substring(data.lastIndexOf('/') + 1);
    },
    preLocalStorage: '',
    doLocalStorage: function() {
      var ls = this._addDot(localStorage);
      if (ls != this.preLocalStorage) {
        this.preLocalStorage = ls;
        send('localStorage:' + ls);
      }
    },
    preSessionStorage: '',
    doSessionStorage: function() {
      var ss = this._addDot(sessionStorage);
      if (ss != this.preSessionStorage) {
        this.preSessionStorage = ss;
        send('sessionStorage:' + ss);
      }
    },
    _addDot: function(obj) {
      var num = 250;
      var rt = {};
      for (var index in obj) {
        rt[index] = obj[index].substr(0, num);
        if (obj[index].length > num) {
          rt[index] += "...";
        }
      }
      return JSON.stringify(rt);
    },
    preCookie: '',
    doCookie: function() {
      var c = document.cookie;
      if (c != this.preCookie) {
        this.preCookie = c;
        send('cookie:' + c);
      }
    },
    doDelLocalStorage: function(key) {
      localStorage[key] = null;
      delete localStorage[key];
    },
    doDelSessionStorage: function(key) {
      sessionStorage[key] = null;
      delete sessionStorage[key];
    },
    doDelCookie: function(key) {
      var date = new Date();
      date.setTime(date.getTime() - 10000);
      document.cookie = key + "=0; expires=" + date.toGMTString();
    },
    doCacheFile: function(data) {
      var index = data.indexOf("_dg_");
      if (index < 1) {
        return;
      }
      var filePath = data.substring(0, index);
      var con = data.substring(index + 4);
      var type = filePath.substring(filePath.lastIndexOf('.') + 1);
      if (type == "js") {
        this._doCacheJs(filePath, con);
      } else if (type == "css") {
        this._doCacheCss(filePath, con);
      }
    },
    _doCacheJs: function(filePath, con) {
      //remove the previous file if it exists
      qs('script[_src="' + filePath + '"]') && qs('script[_src="' + filePath + '"]').remove();
      qs('#debuggapRoot').appendChild(dg.createEle('script', {
        _src: filePath
      }, con));
    },
    _doCacheCss: function(filePath, con) {
      //remove the previous file if it exists
      var styleTag = null;
      if (qs('style[_href="' + filePath + '"]')) {
        styleTag = qs('style[_href="' + filePath + '"]');
      } else {
        styleTag = job.deepFinder('link', filePath);
      }
      styleTag.parentNode.insertBefore(dg.createEle('style', {
        _href: filePath
      }, con), styleTag);
      styleTag.remove();
    },
    //draw the shadow according to relation from remote client.
    doRelationToEle: function(s) {
      s = s.split(',');
      var node = dg.draw.findRelation(s);
      if (node.nodeType == 1) {
        //close the debuggap client
        dg.doc.trigger(qs('#debuggapBlock .dg-center'), 'tap');
        //draw the shadow
        dg.map.drawShadow(node);
        dg.scale();
      }
    },

    doGetCalculateCss: function(s) {
      s = s.split(',');
      s = dg.draw.findRelation(s);
      this._getCalculateCss(s);
    },
    //get css property
    _getCalculateCss: function(a) {
      var obj = calculateCss(a);
      send('calculateCss:' + JSON.stringify(obj));
    },

    _resetCssForElement: function(node) {
      dg.map.drawShadow(node);

      //calculate the css again
      this._getCalculateCss(node);
    },

    doAddCssForElement: function(a) {
      var arr = a.split(';');
      var node = dg.draw.findRelation(arr[0].split(','));
      var style = node.getAttribute('style');
      if (!style) {
        style = '';
      } else {
        style = style.replace(/;*$/, ';');
      }
      node.setAttribute('style', style + arr[1]);

      //calculate the css again
      this._getCalculateCss(node);
    },

    doRemoveCssForElement: function(a) {
      var arr = a.split(';');
      var node = dg.draw.findRelation(arr[0].split(','));
      var style = dg.trim(node.getAttribute('style'));
      style = style.replace(/^;+|;+$/g, "");
      style = style.split(';');
      style.splice(parseInt(arr[1]), 1);
      style = style.join(';');
      node.setAttribute('style', style);

      //calculate the css again
      this._getCalculateCss(node);
    },

    doReplaceCssForElement: function(a) {
      var arr = a.split(';');
      var node = dg.draw.findRelation(arr[0].split(','));
      var style = dg.trim(node.getAttribute('style'));
      style = style.replace(/^;+|;+$/g, "");
      style = style.split(';');
      style[arr[1]] = arr[2];
      style = style.join(';');
      node.setAttribute('style', style);

      //calculate the css again
      this._getCalculateCss(node);
    },

    styleCache: {},
    doActiveCssForElement: function(a) {
      var arr = a.split(';');
      var node = dg.draw.findRelation(arr[0].split(','));
      var style = dg.trim(node.getAttribute('style'));
      style = style.replace(/^;+|;+$/g, "");
      style = style.split(';');
      if (style && style[arr[1]]) {
        if (arr[2] == 'active') {
          var reg = new RegExp('/\\*+([^*]+)\\*+/');
          style[arr[1]] = style[arr[1]].replace(reg, '$1');
        } else {
          style[arr[1]] = '/*' + style[arr[1]] + '*/';
        }
        style = style.join(';');
        node.setAttribute('style', style);
      }

      //calculate the css again
      this._getCalculateCss(node);
    },

    doReplaceClassItem: function(a) {
      //arr[relation,sheet index,item index,value]
      var arr = a.split(';');
      var node = dg.draw.findRelation(arr[0].split(','));
      var indexArray = arr[1].split(':');
      var value = decodeURIComponent(arr[2]);
      if (indexArray && typeof indexArray[1] != 'undefined') {
        var styleSheet = document.styleSheets[indexArray[0]];
        var index = indexArray[1];
        if (indexArray.length == 3) {
          //replace media css
          var mediaCss = this._getMediaCss(styleSheet.cssRules[index]);
          mediaCss[indexArray[2]] = value;
          //match the media text
          var match = styleSheet.cssRules[index].cssText.match(/@\s*media\s+[^{]+/);
          value = match[0] + '{\n' + mediaCss.join('\n') + '\n}';
        }
        if (dg.browser == 'ie') {
          styleSheet.deleteRule(index);
          styleSheet.insertRule(value, index);
        } else {
          styleSheet.removeRule(index);
          styleSheet.insertRule(value, index);
        }
      }
      //calculate the css again
      this._getCalculateCss(node);
    },

    _getMediaCss: function(mediaRule) {
      var arr = [];
      var cssRules = mediaRule.cssRules;
      if (cssRules) {
        for (var i = 0, len = cssRules.length; i < len; i++) {
          arr.push(cssRules[i].cssText);
        }
      }
      return arr;
    },

    //get the prompt for input
    doGetPrompt: function(str) {
      var timestamp = str.substr(0, str.indexOf(':'));
      var value = str.substr(str.indexOf(':') + 1);
      var arr = value.split('.');
      var obj = window;
      var len = arr.length;
      for (var i = 0; i < len - 1; i++) {
        try {
          obj = obj[arr[i]];
        } catch (e) {
          send('prompt:' + timestamp + ':' + JSON.stringify({
            msg: e.message
          }));
        }
      }

      try {
        var rt = [];
        var reg = new RegExp('^' + arr[len - 1]);
        for (var i in obj) {
          if (reg.test(i)) {
            rt.push(i);
          }
        }
        send('prompt:' + timestamp + ':' + JSON.stringify(rt));
      } catch (e) {}

    },

    doCleanInspect: function() {
      //clean the inspect shadow
      dg.doc.trigger(qs('#debuggapBlock .dg-center'), 'tap');
    },

    doStartInspect: function() {
      //trigger inspect function

      this.doCleanInspect();
      dg.doc.bind(document, 'taps', function(e) {
        dg.doc.unbind(document);
        //notice remote to close the inspect function
        send("closeInspect:", true);

        var ele = e.changedTouches && e.changedTouches[0].target || e.target;
        //except for the spot
        if (!dg.inArray(ele.className, ['dg-inner', 'dg-out'])) {
          dg.map.eleToTree(ele);
        }
        e.preventDefault();
      });
    },

    doCloseInspect: function() {
      //close inspect functionality
      dg.doc.unbind(document);
      this.doCleanInspect();
    }
  }

  //tool for remote debug
  dg.extend(job, {
    deepFinder: function(tag, attr) {
      var index = (tag == "script" ? 'src' : 'href');
      var s = qsa(tag);
      for (var i = 0; i < s.length; i++) {
        if (s[i][index] == attr) {
          return s[i];
        }
      }
      return null;
    }
  });

  //extend the websocket method
  var socket;

  function send(msg, vip) {

    if (vip) {
      dg.socketBuffer.unshift(msg);
    } else {
      dg.socketBuffer.push(msg);
    }
    if (!job.socketReady() || !dg.socketSendStop) {
      return;
    }
    dg.socketSendStop = 0;
    dg._sendMessage();
  }
  dg.extend({
    socketBuffer: [],
    socketTimeout: 0,
    socketSendStop: 1,
    _sendMessage: function() {
      if (dg.socketBuffer.length > 0) {

        var data = dg.socketBuffer.shift();
        data = encodeURIComponent(data);
        setTimeout(function() {
          socket.send(data);
          var timeout = Math.ceil(data.length / 50);
          if (timeout > 5000) {
            timeout = 5000;
          } else if (timeout < 50) {
            timeout = 50;
          }
          dg.socketTimeout = timeout;

          if (dg.socketBuffer.length == 0) {
            dg.socketSendStop = 1;
            if (timeout > 500) {
              dg.socketTimeout = timeout;
            }
          } else {
            dg._sendMessage();
          }

        }, dg.socketTimeout);
      }
    },
    _getCurrentAddr: function() {
      var rt = [];
      var scripts = document.scripts,
        result;
      for (var i = 0, len = scripts.length; i < len; i++) {
        result = scripts[i].src.match(/\?(.*)/);
        if (result && result.length == 2) {
          rt = result[1].split(':');
          break;
        }
      }
      return rt;
    },
    decodeMessage: function(data) {
      var arr = [];
      for (var i = 0; i < data.length; i += 2) {
        arr.push(parseInt(data.charCodeAt(i).toString(16).substr(1, 1) + data.charCodeAt(i + 1).toString(16).substr(1, 1), 16));
      }
      var mask = arr.splice(0, 4);
      var j = 0;
      var str = "";
      for (var i = 0; i < arr.length; i++) {
        str += String.fromCharCode(mask[j++ % 4] ^ arr[i]);
      }
      return str;
    },
    distributeMessage: function(data) {
      //data = dg.decodeMessage(data);
      data = decodeURIComponent(data);
      var index = data.indexOf(":");
      if (index < 1) {
        return;
      }
      var type = data.substring(0, index);
      var data = data.substring(index + 1);

      var action = "do" + type[0].toUpperCase() + type.substring(1);
      try {
        job[action](data);
      } catch (e) {
        console.error(e.message);
      }
    },
    initSocketMethod: function(socket) {
      socket.onopen = function(msg) {
        socket.send(encodeURIComponent('initClient:' + dg.version + '_debuggap_' + navigator.userAgent + '_debuggap_' + location.href));
        qs('#dgConnect') && (qs('#dgConnect').value = 'Connect');
      };
      socket.onmessage = function(msg) {
        dg.distributeMessage(msg.data);
      };
      socket.onclose = function(msg) {
        if (dg.scriptSocketFlag) {
          qs('#dgConnect') && (qs('#dgConnect').value = 'Connect');
          console.error("Please check your network,client could not talk with server!");
        }
      };
    },
    scriptSocketFlag: 0,
    initSocket: function(conf) {
      this.scriptSocketFlag = 0;
      var addr = "ws://" + conf.host + ":" + conf.port;
      if (conf.name) {
        addr += ("/" + conf.name);
      }

      try {
        socket = new WebSocket(addr, conf.protocal);
      } catch (ex) {
        socket = null
        console.log(ex);
      }

      if (!socket) {
        socket = new ScriptSocket(conf);
        this.scriptSocketFlag = 1;
      }
      this.initSocketMethod(socket);

      if (!this.scriptSocketFlag) {
        var self = this;
        //daemon
        setTimeout(function() {
          if (socket && socket.readyState != 1) {
            self.scriptSocketFlag = 1;
            socket = new ScriptSocket(conf);
            self.initSocketMethod(socket);
          }
        }, 2000);
      }
    }
  });

  //automaticly render the spot
  window.addEventListener('DOMContentLoaded', function() {
    dg.ready()
  }, false)

  //error exception
  window.addEventListener('error', function(e) {
    if (e instanceof ErrorEvent) {
      if (/debuggap\.js/.test(e.filename)) {
        return
      }
      console.error("Error:", e.message + ' at ' + e.filename + ':' + e.lineno + ':' + e.colno);
    } else {
      console.error('Error:', e)
    }
  }, false)

  /********** support the different frameworks **********/

  dg.inherit({

  });

  dg.extend(job, {
    _doCacheJs: function(filePath, con) {
      var result = job.filterCon(con);

      if (result.length) {
        job.setPrototype(result);
      } else {
        //remove the previous file if it exists
        qs('script[_src="' + filePath + '"]') && qs('script[_src="' + filePath + '"]').remove();
        qs('#debuggapRoot').appendChild(dg.createEle('script', {
          _src: filePath
        }, con));
      }
    },
    filterCon: function(con) {
      var index = 0;
      var result = [];
      do {
        var pos = con.indexOf("enyo.kind");
        if (pos != -1) {
          con = con.replace('enyo.kind', '');
          var stack = [];
          for (var i = index; i < con.length; i++) {
            var code = con.charCodeAt(i);
            if (code == 123) {
              stack.push(i);
            } else if (code == 125) {
              if (stack.length < 1) {
                alert("remote debug error");
                break;
              } else if (stack.length == 1) {
                stack.push(i);
                index = i + 1;
                break;
              } else {
                stack.pop();
              }
            }
          }

          if (stack.length == 2) {
            result.push(con.substring(stack[0], stack[1] + 1));
          } else {
            alert("remote debug error");
          }
        }
      } while (pos != -1);
      return result;
    },
    setPrototype: function(con) {
      for (var i = 0; i < con.length; i++) {
        var obj = new Function("return " + con[i])();
        var path = obj.name ? obj.name : (obj.kind ? obj.kind : null);
        if (path) {
          var _class = enyo.getPath(path);
          for (var type in obj) {
            if (dg.isFunction(obj[type])) {
              _class.prototype[type] = obj[type];
            }
          }
        }
      }
    }
  });

})();