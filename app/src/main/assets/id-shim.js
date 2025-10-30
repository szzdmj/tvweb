/*
 * Android 4.4.4 WebView id 映射补丁 v2
 * 目标：
 *  1) 为常用 id 定义 window 访问器（getter），同步返回 getElementById(name)；
 *  2) 监听 DOMNodeInserted（同步），新插入节点立即挂到 window；
 *  3) 在首秒内做高频短时轮询，尽早把关键 id 绑定到 window，避免早期脚本取到 null；
 *  4) DOMContentLoaded 后再做一次全量兜底扫描。
 */
(function(){
  // 1) 预定义 getter：访问 window.top12 时，实际返回 document.getElementById('top12')
  function defineIdAccessor(name){
    if (!name || name in window) return;
    try {
      Object.defineProperty(window, name, {
        configurable: true,
        enumerable: false,
        get: function(){ return document.getElementById(name); }
      });
    } catch (e) {
      // 极少数环境不允许 defineProperty 到 window —— 降级为占位
      try { window[name] = null; } catch(_) {}
    }
  }

  // 2) 将具体节点对象同步挂到 window（避免早期脚本拿到 null）
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

  // 3) 收集常见/关键 id（可按需扩展）
  var COMMON_IDS = [
    'top12','toptu','divDDMXS','divDDM','divMenu2','btnMenu','svgMenu',
    'topMainLeft','topMainRight','Mainleft','Mainright',
    'BottomTop','InBottomMain','vp','divPlayList',
    'aPrev','aNext','bq','tbNav','spIndex','spContent','help',
    'd0','d1','d2','d3','d4','d5','td0','td1','td2','td3','td4','td5','td6',
    'circle','demo','demo1','demo2'
  ];
  for (var i = 1; i <= 40; i++) COMMON_IDS.push('inMainleft' + i);

  // 为这些 id 预定义访问器
  for (var i = 0; i < COMMON_IDS.length; i++) defineIdAccessor(COMMON_IDS[i]);

  // 4) 旧版 DOM Mutation 事件（同步触发），第一时间把新节点挂上 window
  try {
    document.addEventListener('DOMNodeInserted', function(ev){
      var el = ev && ev.target;
      if (el && el.nodeType === 1) {
        bindNodeToWindow(el);
        if (el.querySelectorAll) bindAllWithId(el);
      }
    }, true);
  } catch(_) {}

  // 5) 首秒内短时轮询（每 20ms 一次，最多 50 次）—— 保障关键 id 早就绪
  (function eagerPoll(){
    var tries = 0, MAX = 50, STEP = 20; // 约 1 秒
    var timer = setInterval(function(){
      tries++;
      bindAllWithId(document);
      // 若关键 id 已基本就绪可提前结束（至少 top12 和 d0 常被最早访问）
      var ok = true;
      for (var j = 0; j < COMMON_IDS.length; j++) {
        var id = COMMON_IDS[j];
        if (id === 'top12' || id === 'd0' || id === 'toptu') {
          if (!window[id]) { ok = false; break; }
        }
      }
      if (ok || tries >= MAX) clearInterval(timer);
    }, STEP);
  })();

  // 6) DOMContentLoaded 兜底扫描
  try {
    document.addEventListener('DOMContentLoaded', function(){
      bindAllWithId(document);
    }, false);
  } catch(_) {}
})();
