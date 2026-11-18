    // F6 / Shift+F6 cycle the focus between the workspace regions.  The
    // regions carry the same focus token as every other control, so the ring
    // is visible when a keyboard user lands on a container.
    (function() {
      var selectors = [
        '[data-rcmdr-focus-region="primary"]',
        '[data-rcmdr-focus-region="secondary"]',
        '[data-rcmdr-focus-region="panel"]',
        '[data-rcmdr-focus-region="modeless"]',
        '[data-rcmdr-focus-region="status"]'
      ];
      function regions() {
        var out = [];
        selectors.forEach(function(selector) {
          Array.prototype.forEach.call(
            document.querySelectorAll(selector),
            function(node) {
              if (!node.getClientRects().length) return;
              if (out.indexOf(node) < 0) out.push(node);
            }
          );
        });
        return out;
      }
      document.addEventListener('keydown', function(event) {
        if (event.key !== 'F6' || event.ctrlKey || event.metaKey ||
            event.altKey) return;
        if (document.querySelector('.modal.show')) return;
        var list = regions();
        if (!list.length) return;
        event.preventDefault();
        var current = -1;
        list.forEach(function(node, index) {
          if (node === document.activeElement ||
              node.contains(document.activeElement)) current = index;
        });
        var step = event.shiftKey ? -1 : 1;
        var next = current < 0
          ? (step > 0 ? 0 : list.length - 1)
          : current + step;
        if (next < 0) next = list.length - 1;
        if (next >= list.length) next = 0;
        list[next].focus();
      });
    })();
    document.addEventListener('keydown', function(event) {
      var mod = event.ctrlKey || event.metaKey;
      var key = (event.key || '').toLowerCase();
      // Ctrl+Z is Ace's undo inside the editor and the browser's undo inside
      // a field; the application stack only takes it outside text entry.
      if (mod && key === 'z' && !event.altKey) {
        var target = event.target;
        var tag = target && target.tagName ? target.tagName.toLowerCase() : '';
        var inText = tag === 'input' || tag === 'textarea' || tag === 'select' ||
          (target && target.isContentEditable) ||
          (target && target.closest && target.closest('.ace_editor'));
        if (!inText) {
          var undoButton = document.getElementById(
            event.shiftKey ? 'redo_shortcut' : 'undo_shortcut'
          );
          if (undoButton) {
            event.preventDefault();
            undoButton.click();
          }
        }
      }
      if (mod && !event.shiftKey && !event.altKey && key === 'k') {
        var paletteButton = document.getElementById('palette_open');
        if (paletteButton) {
          event.preventDefault();
          paletteButton.click();
        }
      }
      if (mod && event.shiftKey && !event.altKey && key === 'p') {
        var paletteShift = document.getElementById('palette_open');
        if (paletteShift) {
          event.preventDefault();
          paletteShift.click();
        }
      }
      if (mod && !event.shiftKey && !event.altKey && key === '/') {
        var shortcuts = document.getElementById('shortcuts_open');
        if (shortcuts) {
          event.preventDefault();
          shortcuts.click();
        }
      }
      if (event.key === 'F1' && !mod && !event.altKey) {
        var helpShortcut = document.getElementById('help_shortcut');
        if (helpShortcut) {
          event.preventDefault();
          helpShortcut.click();
        }
      }
      if (event.altKey && !mod && !event.shiftKey && /^[1-9]$/.test(event.key)) {
        var tabs = document.querySelectorAll('#main_tabs .nav-link');
        var index = parseInt(event.key, 10) - 1;
        if (tabs[index]) {
          event.preventDefault();
          tabs[index].click();
        }
      }
      if (mod && event.shiftKey && event.key === 'Enter') {
        var runAll = document.getElementById('run_all');
        if (runAll) {
          event.preventDefault();
          runAll.click();
        }
      }
      if (mod && !event.shiftKey && !event.altKey && key === 's') {
        var save = document.getElementById('document_save');
        if (save) {
          event.preventDefault();
          save.click();
        }
      }
      if (mod && event.shiftKey && key === 's') {
        var saveAs = document.getElementById('document_save_as');
        if (saveAs) {
          event.preventDefault();
          saveAs.click();
        }
      }
      if (event.key === 'Enter' && mod && !event.shiftKey && !event.target.matches('#console_input, #palette_query')) {
        var run = document.getElementById('run_selection');
        if (run) {
          event.preventDefault();
          run.click();
        }
      }
      if (event.target.id === 'console_input' && event.key === 'Enter' && !event.shiftKey) {
        event.preventDefault();
        var consoleRun = document.getElementById('console_run');
        if (consoleRun) consoleRun.click();
      }
      if (event.target.id === 'console_input' &&
          (event.key === 'ArrowUp' || event.key === 'ArrowDown')) {
        var historyButton = document.getElementById(
          event.key === 'ArrowUp' ? 'console_prev' : 'console_next'
        );
        if (historyButton) {
          event.preventDefault();
          historyButton.click();
        }
      }
    });
    function rcmdrPaletteActivate(results, index) {
      results.forEach(function(el) {
        el.classList.remove('active');
        el.setAttribute('aria-selected', 'false');
      });
      var active = results[index];
      if (!active) return;
      active.classList.add('active');
      active.setAttribute('aria-selected', 'true');
      var query = document.getElementById('palette_query');
      if (query && active.id) {
        query.setAttribute('aria-activedescendant', active.id);
      }
      active.scrollIntoView({block: 'nearest'});
    }
    document.addEventListener('keydown', function(event) {
      if (event.target.id !== 'palette_query') return;
      var results = Array.from(document.querySelectorAll('#palette_results .rcmdr-palette-result:not(.disabled)'));
      if (results.length === 0) return;
      var current = results.findIndex(function(el) { return el.classList.contains('active'); });
      if (event.key === 'ArrowDown') {
        event.preventDefault();
        rcmdrPaletteActivate(results,
          Math.min(results.length - 1, current + 1));
      } else if (event.key === 'ArrowUp') {
        event.preventDefault();
        rcmdrPaletteActivate(results,
          Math.max(0, current <= 0 ? 0 : current - 1));
      } else if (event.key === 'Home') {
        event.preventDefault();
        rcmdrPaletteActivate(results, 0);
      } else if (event.key === 'End') {
        event.preventDefault();
        rcmdrPaletteActivate(results, results.length - 1);
      } else if (event.key === 'Enter') {
        event.preventDefault();
        if (current < 0) current = 0;
        results[current].click();
      }
    });
    // A new query rebuilds the list: drop the stale active descendant so the
    // screen reader does not announce an option that no longer exists.
    document.addEventListener('input', function(event) {
      if (event.target.id !== 'palette_query') return;
      event.target.removeAttribute('aria-activedescendant');
    });
    // Accordion headers: Bootstrap leaves the arrow keys to the page, so
    // Up/Down move inside the same accordion and Home/End jump to the edges.
    // Nested accordions only see their own headers; Esc stays with the modal.
    document.addEventListener('keydown', function(event) {
      var target = event.target;
      var button = target && target.closest &&
        target.closest('.accordion-button');
      if (!button) return;
      var accordion = button.closest('.accordion');
      if (!accordion || !accordion.classList.contains('rcmdr-accordion')) return;
      if (event.altKey || event.ctrlKey || event.metaKey) return;
      var headers = Array.prototype.filter.call(
        accordion.querySelectorAll('.accordion-button'),
        function(el) {
          return el.closest('.accordion') === accordion &&
            el.getClientRects().length > 0;
        }
      );
      var index = headers.indexOf(button);
      if (index < 0) return;
      var next = null;
      if (event.key === 'ArrowDown') {
        next = headers[Math.min(headers.length - 1, index + 1)];
      } else if (event.key === 'ArrowUp') {
        next = headers[Math.max(0, index - 1)];
      } else if (event.key === 'Home') {
        next = headers[0];
      } else if (event.key === 'End') {
        next = headers[headers.length - 1];
      }
      if (!next) return;
      event.preventDefault();
      next.focus();
    });
    
