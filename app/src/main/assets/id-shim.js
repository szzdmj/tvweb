/*
 * Android 4.4.4 WebView id 映射补丁 v3（更强约束）
 * 目标：
 *  1) 为常用 id 定义“非可配置”的 window 属性（getter：document.getElementById(name)），阻止后续 var 覆盖；
 *  2) 监听 DOMNodeInserted（同步），新插入节点即时挂到 window；
 *  3) 首秒内高频短时轮询（每 20ms 共 50 次），尽快把关键 id 绑定到 window；
 *  4) DOMContentLoaded 兜底全量扫描；
 *  5) onerror 捕获 "XXX is not defined" 动态补齐 window.XXX getter，最大化容错。
 */
(function(){
  // 1) 定义严格 getter：不可配置、可读不可写，阻止 var 重定义与赋值
  function defineIdAccessorStrict(name){
    if (!name || name in window) return;
    try {
      Object.defineProperty(window, name, {
        configurable: false,   // 关键：后续 var XXX 不会再创建/覆盖
        enumerable: false,
        get: function(){ return document.getElementById(name); },
        set: function(_){ /* 忽略外部赋值，保持指向 DOM */ }
      });
    } catch(_){}
  }

  // 2) 将具体节点对象同步挂到 window（作为额外冗余）
  function bindNodeToWindow(el){
    if (!el || el.nodeType !== 1) return;
    var id = el.id;
    if (!id) return;
    if (!(id in window)) {
      try { window[id] = el; } catch(_) {}
    }
  }

  function bindAllWithId(root){
    try {
      var list = (root || document).querySelectorAll('[id]');
      for (var i = 0; i < list.length; i++) bindNodeToWindow(list[i]);
    } catch(_) {}
  }

  // 3) 常用/关键 id 列表（可按需扩展）
  var COMMON_IDS = [
    'top12','toptu','divDDMXS','divDDM','divMenu2','btnMenu','svgMenu',
    'topMainLeft','topMainRight','Mainleft','Mainright',
    'BottomTop','InBottomMain','vp','divPlayList',
    'aPrev','aNext','bq','tbNav','spIndex','spContent','help',
    'd0','d1','d2','d3','d4','d5','td0','td1','td2','td3','td4','td5','td6',
    'circle','demo','demo1','demo2','item','btn-left','btn-right'
  ];
  for (var i = 1; i <= 80; i++) COMMON_IDS.push('inMainleft' + i);

  // 预定义严格 getter
  for (var i = 0; i < COMMON_IDS.length; i++) defineIdAccessorStrict(COMMON_IDS[i]);

  // 4) 同步监听，新节点立刻挂到 window
  try {
    document.addEventListener('DOMNodeInserted', function(ev){
      var el = ev && ev.target;
      if (el && el.nodeType === 1) {
        bindNodeToWindow(el);
        if (el.querySelectorAll) bindAllWithId(el);
      }
    }, true);
  } catch(_) {}

  // 5) 首秒内高频短时轮询（约 1s）：尽快让关键 id 就绪
  (function eagerPoll(){
    var tries = 0, MAX = 50, STEP = 20; // 50*20ms ≈ 1s
    var timer = setInterval(function(){
      tries++;
      bindAllWithId(document);
      // 提前收敛判断：最常被早期访问的 id
      var ok = !!(window.top12 && window.d0);
      if (ok || tries >= MAX) clearInterval(timer);
    }, STEP);
  })();

  // 6) DOMContentLoaded 兜底全量扫描
  try {
    document.addEventListener('DOMContentLoaded', function(){
      bindAllWithId(document);
    }, false);
  } catch(_) {}

  // 7) onerror 动态补齐“未定义变量” -> 定义 getter 并允许继续
  try {
    window.addEventListener('error', function(e){
      var msg = (e && e.message) || '';
      // 匹配 ReferenceError: XXX is not defined
      var m = /(?:ReferenceError: )?([A-Za-z_][A-Za-z0-9_]*) is not defined/.exec(msg);
      if (m && m[1]) {
        var name = m[1];
        // 动态给这个变量名补一个严格 getter
        defineIdAccessorStrict(name);
        // 再做一次绑定扫描
        bindAllWithId(document);
        // 返回后让脚本继续（本次抛错没法重放，但后续再访问即可命中）
        // 某些旧环境不支持 preventDefault，这里不强制拦截
      }
    }, true);
  } catch(_) {}
})();
