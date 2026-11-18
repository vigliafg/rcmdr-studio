window.rcmdrApplyMode = function(mode) {
      var body = document.body;
      if (!body) return;
      var studio = mode !== 'classic';
      body.classList.toggle('rcmdr-mode-studio', studio);
      body.classList.toggle('rcmdr-mode-classic', !studio);
      body.setAttribute('data-rcmdr-mode', studio ? 'studio' : 'classic');
    };
    Shiny.addCustomMessageHandler('rcmdr-ui-mode', function(mode) {
      window.rcmdrApplyMode(mode);
    });
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', function() {
        window.rcmdrApplyMode('studio');
      });
    } else {
      window.rcmdrApplyMode('studio');
    }
    Shiny.addCustomMessageHandler('rcmdr-click', function(id) {
      var el = document.getElementById(id);
      if (el) el.click();
    });
    window.rcmdrSetView = function(view) {
      if (!view) return false;
      Shiny.setInputValue('main_tabs', view, {priority: 'event'});
      return false;
    };
    window.rcmdrClickSubTab = function(barId, value, tries) {
      var bar = document.getElementById(barId);
      var link = bar && value
        ? bar.querySelector('.nav-link[data-value="' + value + '"]')
        : null;
      if (link) {
        link.click();
        return;
      }
      if ((tries || 0) < 20) {
        window.setTimeout(function() {
          window.rcmdrClickSubTab(barId, value, (tries || 0) + 1);
        }, 50);
      }
    };
    window.rcmdrApplySidebar = function(collapsed) {
      var body = document.querySelector('.rcmdr-shell-body');
      if (!body) return false;
      body.classList.toggle('rcmdr-sidebar-collapsed', !!collapsed);
      var button = document.querySelector('[data-rcmdr-sidebar-toggle]');
      if (button) {
        button.setAttribute('aria-expanded', collapsed ? 'false' : 'true');
      }
      return !!collapsed;
    };
    window.rcmdrToggleSidebar = function(button) {
      var body = document.querySelector('.rcmdr-shell-body');
      if (!body) return false;
      var collapsed = body.classList.toggle('rcmdr-sidebar-collapsed');
      if (button) {
        button.setAttribute('aria-expanded', collapsed ? 'false' : 'true');
      }
      Shiny.setInputValue('sidebar_collapsed', collapsed, {priority: 'event'});
      return false;
    };
    Shiny.addCustomMessageHandler('rcmdr-sidebar', function(message) {
      window.rcmdrApplySidebar(message && message.collapsed);
    });
    Shiny.addCustomMessageHandler('rcmdr-tab', function(message) {
      // The server sends {tab, sub} with stable view ids; a plain string is
      // still accepted for older callers.
      var target = (typeof message === 'string') ? { tab: message } : (message || {});
      var workspace = document.getElementById('workspace_layout');
      if (workspace) {
        window.rcmdrSetView(target.tab);
        if (target.sub) {
          window.rcmdrClickSubTab('console_tabs', target.sub, 0);
        }
        return;
      }
      var bar = document.getElementById('main_tabs');
      if (!bar) return;
      var link = target.tab
        ? bar.querySelector('.nav-link[data-value="' + target.tab + '"]')
        : null;
      if (!link) {
        link = Array.from(bar.querySelectorAll('.nav-link')).find(function(a) {
          return a.textContent.trim() === target.tab;
        });
      }
      if (!link) return;
      link.click();
      if (!target.sub) return;
      var href = link.getAttribute('href');
      var pane = href ? document.querySelector(href) : null;
      var sub = pane
        ? pane.querySelector('.nav-link[data-value="' + target.sub + '"]')
        : null;
      if (sub) sub.click();
    });
    Shiny.addCustomMessageHandler('rcmdr-focus', function(id) {
      var el = document.getElementById(id);
      if (el) el.focus();
    });
