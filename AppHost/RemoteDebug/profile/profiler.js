/**
 * Timing - Presents visually the timing of different
 * page loading phases by a browser. (https://github.com/kaaes/timing)
 * Copyright (c) 2011-2013, Kasia Drzyzga. (FreeBSD License)
 */
function __Profiler() {
  this.totalTime = 0;
  
  this.barHeight = 18;
  this.timeLabelWidth = 50;
  this.nameLabelWidth = 160;
  this.textSpace = this.timeLabelWidth + this.nameLabelWidth;
  this.spacing = 1.2;
  this.unit = 1;
  this.fontStyle = "11.5px Arial";
  this.containerPadding = 20;

  this.container = null;
  this.customElement = false;

  this.timingData = [];
  this.sections = [];
};

/**
 * The order of the events is important,
 * store it here.
 */
__Profiler.prototype.eventsOrder = [
  'navigationStart', 'redirectStart', 'redirectStart',
  'redirectEnd', 'fetchStart', 'domainLookupStart',
  'domainLookupEnd', 'connectStart', 'secureConnectionStart',
  'connectEnd', 'requestStart', 'responseStart', 'responseEnd',
  'unloadEventStart', 'unloadEventEnd', 'domLoading',
  'domInteractive', 'msFirstPaint', 'domContentLoadedEventStart',
  'domContentLoadedEventEnd', 'domContentLoaded', 'domComplete',
  'loadEventStart', 'loadEventEnd'
];

/**
 * CSS strings for various parts of the chart
 */
__Profiler.prototype.cssReset = 'font-size:12px;line-height:1em;z-index:99999;text-align:left;' +
  'font-family:Calibri,\'Lucida Grande\',Arial,sans-serif;text-shadow:none;box-' +
  'shadow:none;display:inline-block;color:#444;font-' +
  'weight:normal;border:none;margin:0;padding:0;background:none;';

__Profiler.prototype.elementCss = 'position:fixed;margin:0 auto;top:' +
  '0;left:0;right:0;border-bottom:solid 1px #EFCEA1;box-shadow:0 2px 5px rgba(0,0,0,.1);';

__Profiler.prototype.containerCss = 'background:#FFFDF2;background:rgba(255,253,242,.99);padding:20px;display:block;';

__Profiler.prototype.headerCss = 'font-size:16px;font-weight:normal;margin:0 0 1em 0;width:auto';

__Profiler.prototype.buttonCss = 'float:right;background:none;border-radius:5px;padding:3px 10px' +
  ';font-size:12px;line-height:130%;width:auto;margin:-7px -10px 0 0;cursor:pointer';

__Profiler.prototype.infoLinkCss = 'color:#1D85B8;margin:1em 0 0 0;';

/**
 * Retrieves performance object keys.
 * Helper function to cover browser
 * inconsistencies.
 *
 * @param {PerformanceTiming} Object holding time data
 * @return {Array} list of PerformanceTiming properties names
 */
__Profiler.prototype._getPerfObjKeys = function(obj) {
  var keys = Object.keys(obj);
  return keys.length ? keys : Object.keys(Object.getPrototypeOf(obj));
}

/**
 * Sets unit used in measurements on canvas.
 * Depends on the lenght of text labels and total
 * time of the page loading.
 */
__Profiler.prototype._setUnit = function(canvas) {
  this.unit = (canvas.width - this.textSpace) / this.totalTime;
}

/**
 * Defines sections of the chart.
 * According to specs there are three:
 * network, server and browser.
 *
 * @return {Array} chart sections.
 */
__Profiler.prototype._getSections = function() {
  return Array.prototype.indexOf ? [{
      name: 'network',
      color: [224, 84, 63],
      firstEventIndex: this.eventsOrder.indexOf('navigationStart'),
      lastEventIndex: this.eventsOrder.indexOf('connectEnd'),
      startTime: 0,
      endTime: 0
    }, {
      name: 'server',
      color: [255, 188, 0],
      firstEventIndex: this.eventsOrder.indexOf('requestStart'),
      lastEventIndex: this.eventsOrder.indexOf('responseEnd'),
      startTime: 0,
      endTime: 0
    }, {
      name: 'browser',
      color: [16, 173, 171],
      firstEventIndex: this.eventsOrder.indexOf('unloadEventStart'),
      lastEventIndex: this.eventsOrder.indexOf('loadEventEnd'),
      startTime: 0,
      endTime: 0
    }] : [];
}

/**
 * Creates main container
 * @return {HTMLElement} container element
 */
__Profiler.prototype._createContainer = function() {
  var container = document.createElement('div');
  var header = this._createHeader();
  var button = this._createCloseButton();

  button.onclick = function(e){
    button.onclick = null;
    container.parentNode.removeChild(container);
  }; // DOM level 0 used to avoid implementing this twice for IE & the rest
  
  container.style.cssText = this.cssReset + this.containerCss;

  if (!this.customElement) {
    container.style.cssText += this.elementCss;
  }

  header.appendChild(button);
  container.appendChild(header);
  return container;
}

/**
 * Creates header
 * @return {HTMLElement} header element
 */
__Profiler.prototype._createHeader = function() {
  var c = document.createElement('div');
  var h = document.createElement('h1');
  var sectionStr = '/ ';
    
  for(var i = 0, l = this.sections.length; i < l; i++) {
    sectionStr += '<span style="color:rgb(' + this.sections[i].color.join(',') + ')">' + this.sections[i].name + '</span> / ';
  }       
        
  h.innerHTML = 'Page Load Time Breakdown ' + sectionStr;
  h.style.cssText = this.cssReset + this.headerCss; 
    
  c.appendChild(h);
    
  return c;
}

/**
 * Creates close buttonr
 * @return {HTMLElement} button element
 */
__Profiler.prototype._createCloseButton = function() {
  var b = document.createElement('button');

  b.innerHTML = 'close this box &times;';
  b.style.cssText = this.cssReset + this.buttonCss;
  
  return b;
}

/**
 * Creates info link
 * @return {HTMLElement} link element
 */
__Profiler.prototype._createInfoLink = function() {
  var a = document.createElement('a');
  a.href = 'http://kaaes.github.com/timing/info.html';
  a.target = '_blank';
  a.innerHTML = 'What does that mean?';
  a.style.cssText = this.cssReset + this.infoLinkCss;

  return a;
}

/**
 * Creates information when performance.timing is not supported
 * @return {HTMLElement} message element
 */
__Profiler.prototype._createNotSupportedInfo = function() {
  var p = document.createElement('p');
  p.innerHTML = 'Navigation Timing API is not supported by your browser';
  return p;
}

/**
 * Creates main bar chart
 * @return {HTMLElement} chart container.
 */
__Profiler.prototype._createChart = function() {
  var chartContainer = document.createElement('div');
    
  var canvas = document.createElement('canvas');
  canvas.width = this.container.clientWidth - this.containerPadding * 2;

  var infoLink = this._createInfoLink();

  this._drawChart(canvas);
    
  chartContainer.appendChild(canvas);
  chartContainer.appendChild(infoLink);
    
  return chartContainer;
}

/**
 * Prepare draw function.
 *
 * @param {HTMLCanvasElement} canvas Canvas to draw on
 * @param {String} mode Either 'block' or 'point' for events
 * that have start and end or the ones that just happen.
 * @param {Object} eventData Additional event information.
 */
__Profiler.prototype._prepareDraw = function(canvas, mode, eventData) {
  var sectionData = this.sections[eventData.sectionIndex];
  
  var barOptions = {
    color : sectionData.color,
    sectionTimeBounds : [sectionData.startTime, sectionData.endTime],
    eventTimeBounds : [eventData.time, eventData.timeEnd],
    label : eventData.label
  }

  return this._drawBar(mode, canvas, canvas.width, barOptions);
}

/**
 * Draws a single bar on the canvas
 *
 * @param {String} mode Either 'block' or 'point' for events
 * that have start and end or the ones that just happen.
 * @param {HTMLCanvasElement} canvas Canvas to draw on.
 * @param {Number} barWidth Width of the bar.
 * @param {Object} options Other bar options.
 *  param {Array} options.color The color to use for rendering
 *                the section.
 *  param {Array} options.sectionTImeBounds Start and end times
 *                for the section. Used to draw semi-transparent
 *                 section bar.
 *  param {Array} options.eventTImeBounds Start and end times for
 *                the event itself. Used to draw event bar.
 *  param {String} options.label Name of the event to show next to
 *                 the bars.
 */
__Profiler.prototype._drawBar = function(mode, canvas, barWidth, options) {
  var start;
  var stop;
  var width;
  var timeLabel;
  var metrics;
  var color = options.color;
  var sectionStart = options.sectionTimeBounds[0];
  var sectionStop = options.sectionTimeBounds[1];
  var nameLabel = options.label;
  var context = canvas.getContext('2d');
    
  if (mode === 'block') {
    start = options.eventTimeBounds[0];
    stop = options.eventTimeBounds[1];
    timeLabel = start + '-' + stop;
  } else {
    start = options.eventTimeBounds[0];
    timeLabel = start;
  }
  timeLabel += 'ms';
    
  metrics = context.measureText(timeLabel);
  if(metrics.width > this.timeLabelWidth) {
    this.timeLabelWidth = metrics.width + 10;
    this.textSpace = this.timeLabelWidth + this.nameLabelWidth;
    this._setUnit(canvas);
  }
    
  return function(context) {
    if(mode === 'block') {
      width = Math.round((stop - start) * this.unit);
      width = width === 0 ? 1 : width;
    } else {
      width = 1;
    }
      
    // row background
    context.strokeStyle = 'rgba(' + color[0] + ',' + color[1] + ',' + color[2] + ',.3)';
    context.lineWidth = 1;
    context.fillStyle = 'rgba(255,255,255,0)';
    context.fillRect(0, 0, barWidth - this.textSpace, this.barHeight);
    context.fillStyle = 'rgba(' + color[0] + ',' + color[1] + ',' + color[2] + ',.05)';
    context.fillRect(0, 0, barWidth - this.textSpace, this.barHeight);
    // context.strokeRect(.5, .5, Math.round(barWidth - this.textSpace -1), Math.round(this.barHeight));

      
    // section bar
    context.shadowColor = 'white';
    context.fillStyle = 'rgba(' + color[0] + ',' + color[1] + ',' + color[2] + ',.2)';
    context.fillRect(Math.round(this.unit * sectionStart), 2, Math.round(this.unit * (sectionStop - sectionStart)), this.barHeight - 4);
      
    // event marker
    context.fillStyle = 'rgb(' + color[0] + ',' + color[1] + ',' + color[2] + ')';
    context.fillRect(Math.round(this.unit * start), 2, width, this.barHeight - 4);
      
    // label
    context.fillText(timeLabel, barWidth - this.textSpace + 10, 2 * this.barHeight / 3);
    context.fillText(nameLabel, barWidth - this.textSpace + this.timeLabelWidth + 15, 2 * this.barHeight / 3);
  }
}

/**
 * Draws the chart on the canvas
 */
__Profiler.prototype._drawChart = function(canvas) {
  var time;
  var eventName;
  var options;
  var skipEvents = [];
  var drawFns = [];

  var context = canvas.getContext('2d');
  
  // needs to be set here for proper text measurement...
  context.font = this.fontStyle;

  this._setUnit(canvas);

  for (var i = 0, l = this.eventsOrder.length; i < l; i++) {
    var evt = this.eventsOrder[i];

    if (!this.timingData.hasOwnProperty(evt)) {
      continue;
    }

    var item = this.timingData[evt];
    var startIndex = evt.indexOf('Start');
    var isBlockStart = startIndex > -1;
    var hasBlockEnd = false;
    
    if (isBlockStart) {
      eventName = evt.substr(0, startIndex);
      hasBlockEnd = this.eventsOrder.indexOf(eventName + 'End') > -1;
    }
    
    if (isBlockStart && hasBlockEnd) {
      item.label = eventName;
      item.timeEnd = this.timingData[eventName + 'End'].time;
      drawFns.push(this._prepareDraw(canvas, 'block', item));
      skipEvents.push(eventName + 'End');
    } else if (skipEvents.indexOf(evt) < 0) {
      item.label = evt;
      drawFns.push(this._prepareDraw(canvas, 'point', item));
    }
  }
    
  canvas.height = this.spacing * this.barHeight * drawFns.length;

  // setting canvas height resets font, has to be re-set
  context.font = this.fontStyle;
  
  var step = Math.round(this.barHeight * this.spacing);

  drawFns.forEach(function(draw) {
    draw.call(this, context);
    context.translate(0, step);
  }, this);
}

/**
 * Matches events with the section they belong to
 * i.e. network, server or browser and sets
 * info about time bounds for the sections.
 */
__Profiler.prototype._matchEventsWithSections = function() {
  var data = this.timingData;

  var sections = this.sections;
  
  for (var i = 0, len = sections.length; i < len; i++) {
    var firstEventIndex = sections[i].firstEventIndex;
    var lastEventIndex = sections[i].lastEventIndex;
      
    var sectionOrder = this.eventsOrder.slice(firstEventIndex, lastEventIndex + 1);
    var sectionEvents = sectionOrder.filter(function(el){
      return data.hasOwnProperty(el);
    });

    sectionEvents.sort(function(a, b){
      return data[a].time - data[b].time;
    })
    
    firstEventIndex = sectionEvents[0];
    lastEventIndex = sectionEvents[sectionEvents.length - 1];

    sections[i].startTime = data[firstEventIndex].time;    
    sections[i].endTime = data[lastEventIndex].time;      
      
    for(var j = 0, flen = sectionEvents.length; j < flen; j++) {
      var item = sectionEvents[j];
      if(data[item]) {
        data[item].sectionIndex = i;      
      }
    }
  }
}

/**
 * Gets timing data and calculates
 * when events occured as the original
 * object contains only timestamps.
 *
 * @return {Object} Hashmap of the event names
 * and times when they occured relatvely to
 * the page load start.
 */
__Profiler.prototype._getData = function() {
  if (!window.performance) {
    return;
  }
  
  var data = window.performance;
  var timingData = data.timing;
  var eventNames = this._getPerfObjKeys(timingData);
  var events = {};

  var startTime = timingData.navigationStart || 0;
  var eventTime = 0;
  var totalTime = 0;
    
  for(var i = 0, l = eventNames.length; i < l; i++) {
    var evt = timingData[eventNames[i]];

    if (evt && evt > 0) {
      eventTime = evt - startTime;
      events[eventNames[i]] = { time: eventTime };

      if (eventTime > totalTime) {
        totalTime = eventTime;
      }
    }
  }

  this.totalTime = totalTime;
    
  return events;
}

/**
 * Actually init the chart
 */
__Profiler.prototype._init = function() {
  this.timingData = this._getData();
  this.sections = this._getSections();
  this.container = this._createContainer();

  if (this.customElement) {
    this.customElement.appendChild(this.container);
  } else {
    document.body.appendChild(this.container);
  }

  var content;

  if (this.timingData && this.sections.length) {
    this._matchEventsWithSections();
    content = this._createChart();
  } else {
    content = this._createNotSupportedInfo();
  }
   
  this.container.appendChild(content);
}

/**
 * Build the overlay with the timing chart
 * @param {?HTMLElement} element If provided
 * the chart will be render in the container.
 * If not provided, container element will be created
 * and appended to the page.
 * @param {?Number} timeout Optional timeout to execute
 * timing info. Can be used to catch all events.
 * if not provided will be executed immediately.
 */
__Profiler.prototype.init = function(element, timeout) {

  if (element instanceof HTMLElement) {
    this.customElement = element;
  }

  if (timeout && parseInt(timeout, 10) > 0) {
    var self = this;
    setTimeout(function() {
      self._init();
    }, timeout);
  } else {
    this._init();
  }
}