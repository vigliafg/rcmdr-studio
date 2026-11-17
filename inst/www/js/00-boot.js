Shiny.addCustomMessageHandler('rcmdr-click', function(id) {
      var el = document.getElementById(id);
      if (el) el.click();
    });
    Shiny.addCustomMessageHandler('rcmdr-tab', function(message) {
      // The server sends {tab, sub} with stable view ids; a plain string is
      // still accepted for older callers.
      var target = (typeof message === 'string') ? { tab: message } : (message || {});
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
