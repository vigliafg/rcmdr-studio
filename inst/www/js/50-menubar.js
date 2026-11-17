    window.rcmdrAlignDropdown = function(group) {
      var panel = group && group.querySelector('.rcmdr-menubar-dropdown');
      var bar = group && group.closest ? group.closest('.rcmdr-menubar') : null;
      if (!panel || !bar) return;
      panel.style.left = '';
      panel.style.right = '';
      panel.style.top = '';
      var margin = 8;
      var groupRect = group.getBoundingClientRect();
      var barRect = bar.getBoundingClientRect();
      var panelRect = panel.getBoundingClientRect();
      var maxLeft = Math.max(margin, window.innerWidth - margin - panelRect.width);
      var targetLeft = Math.min(Math.max(groupRect.left, margin), maxLeft);
      panel.style.left = Math.round(targetLeft - groupRect.left) + 'px';
      if (groupRect.bottom < barRect.bottom) {
        panel.style.top = Math.round(barRect.bottom - groupRect.top + 2) + 'px';
      }
    };
    // The menu tree is re-rendered by the server (tick()), which replaces the
    // open <details> elements.  Remember the open top-level group so it can be
    // reopened after a re-render instead of closing under the pointer.
    var rcmdrOpenMenubarGroup = null;
    window.rcmdrRestoreMenubar = function() {
      if (!rcmdrOpenMenubarGroup) return;
      var groups = document.querySelectorAll('.rcmdr-menubar-group');
      var group = null;
      for (var i = 0; i < groups.length; i++) {
        if (groups[i].getAttribute('data-menu-group') === rcmdrOpenMenubarGroup) {
          group = groups[i];
          break;
        }
      }
      if (!group) return;
      if (!group.open) group.open = true;
      window.rcmdrAlignDropdown(group);
    };
    if (window.MutationObserver) {
      var rcmdrMenubarObserver = new MutationObserver(function(records) {
        if (!rcmdrOpenMenubarGroup) return;
        for (var i = 0; i < records.length; i++) {
          var target = records[i].target;
          if (!target || target.nodeType !== 1) continue;
          if (target.id === 'menubar' ||
              (target.closest && target.closest('#menubar'))) {
            window.rcmdrRestoreMenubar();
            return;
          }
        }
      });
      rcmdrMenubarObserver.observe(document.documentElement,
                                   { childList: true, subtree: true });
    }
    var closeMenubarGroups = function() {
      rcmdrOpenMenubarGroup = null;
      document.querySelectorAll('.rcmdr-menubar-group[open]').forEach(function(el) {
        el.open = false;
      });
    };
    document.addEventListener('click', function(event) {
      var target = event.target;
      if (target && target.closest) {
        // A disabled item only carries its reason; keep the menu open.
        if (target.closest('.rcmdr-menubar .rcmdr-menu-item.disabled')) return;
        // Choosing an item closes the menu, as a menubar is expected to do.
        if (target.closest('.rcmdr-menubar .rcmdr-menu-item')) {
          closeMenubarGroups();
          return;
        }
        if (target.closest('.rcmdr-menubar')) return;
      }
      closeMenubarGroups();
    }, true);
    document.addEventListener('toggle', function(event) {
      var target = event.target;
      if (!target || !target.matches) return;
      if (target.matches('.rcmdr-menubar-group')) {
        var groupId = target.getAttribute('data-menu-group');
        if (target.open) {
          rcmdrOpenMenubarGroup = groupId;
          document.querySelectorAll('.rcmdr-menubar-group[open]').forEach(function(el) {
            if (el !== target) el.open = false;
          });
          window.rcmdrAlignDropdown(target);
        } else if (groupId && groupId === rcmdrOpenMenubarGroup && target.isConnected) {
          // A re-render removes the old group, which also reports a close; only
          // a close from a group still in the page is a real user action.
          rcmdrOpenMenubarGroup = null;
        }
      }
      if (!target.matches('details[data-menu-id]')) return;
      Shiny.setInputValue('menu_group_toggle', {
        id: target.getAttribute('data-menu-id'),
        open: target.open
      }, {priority: 'event'});
    }, true);
    window.rcmdrHistoryClick = function(el, action) {
      if (!el) return false;
      if (action === 'copy') {
        rcmdrCopy(el.getAttribute('data-history-command'));
        return false;
      }
      Shiny.setInputValue('history_action', {
        id: el.getAttribute('data-history-id'),
        action: action
      }, {priority: 'event'});
      return false;
    };
