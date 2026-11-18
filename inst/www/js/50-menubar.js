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
        var summary = target.querySelector('summary');
        if (summary) summary.setAttribute('aria-expanded', target.open ? 'true' : 'false');
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
    // Menubar keyboard: F10 enters, Alt+letter opens a group, arrows move.
    document.addEventListener('keydown', function(event) {
      var bar = document.querySelector('.rcmdr-menubar');
      if (!bar) return;
      var groups = Array.prototype.slice.call(
        bar.querySelectorAll('.rcmdr-menubar-group')
      );
      if (!groups.length) return;
      var summaries = groups.map(function(group) {
        return group.querySelector('summary');
      });
      var current = summaries.indexOf(document.activeElement);
      var altLetter = event.altKey && !event.ctrlKey && !event.metaKey &&
        /^[a-zA-Z]$/.test(event.key || '');
      if (event.key === 'F10' || altLetter) {
        event.preventDefault();
        var target = groups[0];
        if (altLetter) {
          var letter = (event.key || '').toLowerCase();
          target = groups.find(function(group) {
            var summary = group.querySelector('summary');
            return summary && summary.textContent.trim().toLowerCase()
              .charAt(0) === letter;
          }) || groups[0];
        }
        current = groups.indexOf(target);
        if (current < 0) current = 0;
        if (!target.open) target.open = true;
        if (summaries[current]) summaries[current].focus();
        window.rcmdrAlignDropdown(target);
        return;
      }
      if (current < 0) return;
      if (event.key === 'ArrowRight' || event.key === 'ArrowLeft') {
        event.preventDefault();
        var step = event.key === 'ArrowRight' ? 1 : -1;
        current = (current + step + groups.length) % groups.length;
        if (summaries[current]) summaries[current].focus();
        return;
      }
      if (event.key === 'ArrowDown') {
        event.preventDefault();
        var group = groups[current];
        if (!group.open) group.open = true;
        window.rcmdrAlignDropdown(group);
        var first = group.querySelector('.rcmdr-menu-item');
        if (first) first.focus();
        return;
      }
      if (event.key === 'Escape') {
        event.preventDefault();
        groups.forEach(function(group) { group.open = false; });
        var summary = groups[current] && groups[current].querySelector('summary');
        if (summary) summary.focus();
      }
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
