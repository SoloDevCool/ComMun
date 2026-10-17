/* Emoji 选择器（纯原生 JS，无依赖）
 * 用法：<input data-emoji-picker>
 * 依赖：public/emoji-data.js（需在本文件之前引入）
 */
(function () {
  var CATEGORIES = ["People", "Nature", "Objects", "Places", "Symbols"];
  var CATEGORY_ICONS = { People: "😀", Nature: "🐻", Objects: "💡", Places: "🚗", Symbols: "❤️" };
  var CATEGORY_NAMES = { People: "人物", Nature: "自然", Objects: "物品", Places: "地点", Symbols: "符号" };
  var styleInjected = false;

  function injectStyle() {
    if (styleInjected) return;
    styleInjected = true;
    var css = [
      ".emoji-picker-panel{position:absolute;z-index:1080;top:calc(100% + 6px);right:0;width:340px;max-width:92vw;background:#fff;",
      "border:1px solid #dee2e6;border-radius:12px;box-shadow:0 8px 30px rgba(0,0,0,.15);display:none;overflow:hidden}",
      ".emoji-picker-tabs{display:flex;border-bottom:1px solid #eee;background:#f8f9fa}",
      ".emoji-picker-tab{flex:1;border:none;background:none;padding:7px 0;font-size:1.05rem;cursor:pointer;opacity:.45;transition:.15s}",
      ".emoji-picker-tab:hover{opacity:.8;background:#eef2ff}",
      ".emoji-picker-tab.active{opacity:1;background:#fff;box-shadow:inset 0 -2px 0 #0d6efd}",
      ".emoji-picker-grid{display:grid;grid-template-columns:repeat(8,1fr);gap:2px;padding:8px;max-height:240px;overflow-y:auto}",
      ".emoji-picker-cell{border:none;background:none;font-size:1.25rem;line-height:1.4;cursor:pointer;border-radius:8px;padding:0}",
      ".emoji-picker-cell:hover{background:#e9ecef;transform:scale(1.15)}",
      ".emoji-picker-footer{display:flex;align-items:center;justify-content:space-between;padding:5px 10px;border-top:1px solid #eee;background:#f8f9fa}",
      ".emoji-picker-preview{font-size:1.15rem;min-height:1.5rem}",
      ".emoji-picker-clear{border:none;background:none;color:#6c757d;font-size:.75rem;cursor:pointer}",
      ".emoji-picker-clear:hover{color:#dc3545;text-decoration:underline}",
      ".emoji-picker-trigger{border:1px solid #dee2e6;border-left:none;background:#f8f9fa;border-radius:0 .375rem .375rem 0;cursor:pointer;font-size:1rem;padding:0 .6rem}",
      ".emoji-picker-trigger:hover{background:#e9ecef}"
    ].join("");
    var style = document.createElement("style");
    style.textContent = css;
    document.head.appendChild(style);
  }

  function createPicker(input) {
    var panel = document.createElement("div");
    panel.className = "emoji-picker-panel";
    panel.style.display = "none";

    var tabs = document.createElement("div");
    tabs.className = "emoji-picker-tabs";

    var grid = document.createElement("div");
    grid.className = "emoji-picker-grid";

    var footer = document.createElement("div");
    footer.className = "emoji-picker-footer";
    footer.innerHTML =
      '<span class="emoji-picker-preview"></span>' +
      '<button type="button" class="emoji-picker-clear">清除已选</button>';
    var preview = footer.querySelector(".emoji-picker-preview");

    function select(emoji) {
      input.value = emoji;
      input.dispatchEvent(new Event("input", { bubbles: true }));
      input.dispatchEvent(new Event("change", { bubbles: true }));
      close();
    }

    function renderGrid(cat) {
      grid.innerHTML = "";
      (window.EMOJI_DATA[cat] || []).forEach(function (emoji) {
        var cell = document.createElement("button");
        cell.type = "button";
        cell.className = "emoji-picker-cell";
        cell.textContent = emoji;
        cell.addEventListener("mouseenter", function () { preview.textContent = emoji; });
        cell.addEventListener("click", function (e) { e.preventDefault(); select(emoji); });
        grid.appendChild(cell);
      });
      tabs.querySelectorAll(".emoji-picker-tab").forEach(function (t) {
        t.classList.toggle("active", t.dataset.cat === cat);
      });
    }

    CATEGORIES.forEach(function (cat) {
      var tab = document.createElement("button");
      tab.type = "button";
      tab.className = "emoji-picker-tab";
      tab.dataset.cat = cat;
      tab.title = CATEGORY_NAMES[cat] || cat;
      tab.textContent = CATEGORY_ICONS[cat] || cat.charAt(0);
      tab.addEventListener("click", function () { renderGrid(cat); });
      tabs.appendChild(tab);
    });

    footer.querySelector(".emoji-picker-clear").addEventListener("click", function (e) {
      e.preventDefault();
      input.value = "";
      input.dispatchEvent(new Event("change", { bubbles: true }));
      close();
    });

    grid.addEventListener("mouseleave", function () { preview.textContent = ""; });
    panel.appendChild(tabs);
    panel.appendChild(grid);
    panel.appendChild(footer);

    var open = false;
    function toggle() {
      open = !open;
      if (open) renderGrid(CATEGORIES[0]);
      panel.style.display = open ? "block" : "none";
    }
    function close() {
      open = false;
      panel.style.display = "none";
    }

    return { panel: panel, toggle: toggle, close: close, isOpen: function () { return open; } };
  }

  function enhance(input) {
    if (input.dataset.emojiPickerReady) return;
    input.dataset.emojiPickerReady = "true";

    var wrapper = document.createElement("div");
    wrapper.style.position = "relative";
    input.parentNode.insertBefore(wrapper, input);

    var trigger = document.createElement("button");
    trigger.type = "button";
    trigger.className = "emoji-picker-trigger";
    trigger.title = "选择 Emoji";
    trigger.textContent = "😊";

    var row = document.createElement("div");
    row.className = "input-group";
    input.classList.add("rounded-end-0");
    row.appendChild(input);
    row.appendChild(trigger);
    wrapper.appendChild(row);

    var picker = createPicker(input);
    wrapper.appendChild(picker.panel);

    trigger.addEventListener("click", function (e) {
      e.preventDefault();
      e.stopPropagation();
      picker.toggle();
    });

    document.addEventListener("click", function (e) {
      if (picker.isOpen() && !picker.panel.contains(e.target) && !trigger.contains(e.target)) {
        picker.close();
      }
    });
    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape") picker.close();
    });
  }

  function init() {
    injectStyle();
    document.querySelectorAll("input[data-emoji-picker]").forEach(enhance);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
