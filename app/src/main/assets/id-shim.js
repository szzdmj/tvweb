/*
 * Android 4.4.4 WebView id 映射补丁
 * 目标：
 *  1) 预先为常用 id 定义 window 访问器（getter），同步返回 getElementById。
 *  2) 监听 DOMNodeInserted（同步），新插入节点立即挂到 window，覆盖内联脚本紧随其后访问的场景。
 *  3) DOMContentLoaded 再做一次全量兜底扫描。
 */
(function(){
  // 尝试为 window 定义一个按需解析的 getter
  function defineIdAccessor(name){
    if (!name) return;
    if (name in window) return;
    try {
      Object.defineProperty(window, name, {
        configurable: true,
        enumerable: false,
        get: function(){ return document.getElementById(name); }
      });
    } catch (e) {
      // 某些环境可能不允许对 window 定义属性，退化为占位（避免 ReferenceError）
      try { window[name] = null; } catch(_) {}
    }
  }

  // 预定义一批已知会被早期脚本使用的 id（可按需扩展）
  var COMMON_IDS = [
    'top12','toptu','divDDMXS','divDDM','divMenu2','btnMenu','svgMenu',
    'topMainLeft','topMainRight','Mainleft','Mainright',
    'BottomTop','InBottomMain','vp','divPlayList',
    'aPrev','aNext','bq','tbNav','spIndex','spContent','help',
    'd0','d1','d2','d3','d4','d5','td0','td1','td2','td3','td4','td5','td6'
  ];
  for (var i = 1; i <= 20; i++) COMMON_IDS.push('inMainleft' + i);

  for (var i = 0; i < COMMON_IDS.length; i++) defineIdAccessor(COMMON_IDS[i]);

  // 将具体节点对象同步挂到 window（避免 getter 也取不到的极端时序）
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

  // 旧版 DOM Mutation 事件（同步），确保在紧随其后的内联脚本执行前映射就绪
  try {
    document.addEventListener('DOMNodeInserted', function(ev){
      var el = ev && ev.target;
      if (el && el.nodeType === 1) {
        bindNodeToWindow(el);
        if (el.querySelectorAll) bindAllWithId(el);
      }
    }, true);
  } catch(_) {}

  // DOMContentLoaded 兜底
  try {
    document.addEventListener('DOMContentLoaded', function(){
      bindAllWithId(document);
    }, false);
  } catch(_) {}
})();
