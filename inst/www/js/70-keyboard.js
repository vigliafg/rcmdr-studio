    document.addEventListener('keydown', function(event) {
      var mod = event.ctrlKey || event.metaKey;
      var key = (event.key || '').toLowerCase();
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
    document.addEventListener('keydown', function(event) {
      if (event.target.id !== 'palette_query') return;
      var results = Array.from(document.querySelectorAll('#palette_results .rcmdr-palette-result:not(.disabled)'));
      if (results.length === 0) return;
      var current = results.findIndex(function(el) { return el.classList.contains('active'); });
      if (event.key === 'ArrowDown') {
        event.preventDefault();
        current = Math.min(results.length - 1, current + 1);
        results.forEach(function(el) { el.classList.remove('active'); });
        results[current].classList.add('active');
        results[current].scrollIntoView({block: 'nearest'});
      } else if (event.key === 'ArrowUp') {
        event.preventDefault();
        current = Math.max(0, current <= 0 ? 0 : current - 1);
        results.forEach(function(el) { el.classList.remove('active'); });
        results[current].classList.add('active');
        results[current].scrollIntoView({block: 'nearest'});
      } else if (event.key === 'Enter') {
        event.preventDefault();
        if (current < 0) current = 0;
        results[current].click();
      }
    });
    
