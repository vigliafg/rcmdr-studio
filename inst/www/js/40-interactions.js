    function rcmdrCopy(text) {
      if (!text) return;
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text);
      }
    }
    window.rcmdrCopy = rcmdrCopy;
    window.rcmdrPaletteClick = function(el) {
      if (!el) return false;
      if (el.getAttribute('data-palette-enabled') === 'false') return false;
      Shiny.setInputValue('palette_action', {
        type: el.getAttribute('data-palette-type'),
        id: el.getAttribute('data-palette-id'),
        action: el.getAttribute('data-palette-action')
      }, {priority: 'event'});
      return false;
    };
    window.rcmdrPaletteAction = function(button, action) {
      if (!button || !button.closest) return false;
      var row = button.closest('.rcmdr-palette-result');
      if (!row) return false;
      if (row.getAttribute('data-palette-enabled') === 'false') return false;
      Shiny.setInputValue('palette_action', {
        type: row.getAttribute('data-palette-type'),
        id: row.getAttribute('data-palette-id'),
        command: row.getAttribute('data-palette-command') || '',
        action: action
      }, {priority: 'event'});
      return false;
    };
    // Open every collapsed panel under `root`.  Used when validation fails:
    // an error inside a closed accordion panel would otherwise stay hidden.
    function rcmdrShowAccordions(root) {
      var scope = root || document;
      var panels = scope.querySelectorAll(
        '.accordion-collapse.collapse:not(.show)'
      );
      Array.prototype.forEach.call(panels, function(panel) {
        var Collapse = window.bootstrap && window.bootstrap.Collapse;
        if (Collapse) {
          Collapse.getOrCreateInstance(panel, {toggle: false}).show();
          return;
        }
        panel.classList.add('show');
        var button = document.querySelector(
          '[data-bs-target="#' + panel.id + '"]'
        );
        if (button) {
          button.classList.remove('collapsed');
          button.setAttribute('aria-expanded', 'true');
        }
      });
    }
    window.rcmdrShowAccordions = rcmdrShowAccordions;
    Shiny.addCustomMessageHandler('rcmdr-open-accordions', function(message) {
      rcmdrShowAccordions();
    });
    // shinyWidgets can change the range of a noUiSlider but not its handle,
    // so the slider wrapper sends this message; .set() fires the binding's
    // change event, which is what updates the Shiny input.
    Shiny.addCustomMessageHandler('rcmdr-set-slider', function(message) {
      var el = document.getElementById(message.id);
      if (!el || !el.noUiSlider) return;
      el.noUiSlider.set(message.value);
    });
    window.rcmdrFocusField = function(id) {
      var el = document.getElementById(id);
      if (!el) el = document.querySelector('[id$="_' + id + '"]');
      if (!el) return false;
      el.classList.add('is-invalid');
      el.setAttribute('aria-invalid', 'true');
      rcmdrShowAccordions(el.closest('.modal') || document);
      // The collapse transition needs a frame before the field is focusable.
      setTimeout(function() {
        if (el.focus) el.focus();
        if (el.scrollIntoView) el.scrollIntoView({block: 'center'});
      }, 200);
      return false;
    };
    Shiny.addCustomMessageHandler('rcmdr-field-errors', function(message) {
      document.querySelectorAll('.is-invalid').forEach(function(el) {
        el.classList.remove('is-invalid');
        el.removeAttribute('aria-invalid');
      });
      var errors = (message && message.errors) || {};
      var first = null;
      Object.keys(errors).forEach(function(id) {
        var el = document.getElementById(id) ||
          document.querySelector('[id$="_' + id + '"]');
        if (!el) return;
        el.classList.add('is-invalid');
        el.setAttribute('aria-invalid', 'true');
        if (!first) first = el;
      });
      if (!first) return;
      rcmdrShowAccordions(first.closest('.modal') || document);
      setTimeout(function() {
        if (first.focus) first.focus();
        if (first.scrollIntoView) first.scrollIntoView({block: 'center'});
      }, 200);
    });
    var rcmdrTourStarted = false;
    function rcmdrTourCheck() {
      if (rcmdrTourStarted) return;
      try {
        if (window.localStorage &&
            window.localStorage.getItem('rcmdr-tour-dismissed') === '1') return;
        if (!window.Shiny || !window.Shiny.setInputValue) return;
        rcmdrTourStarted = true;
        Shiny.setInputValue('tour_start', Date.now(), {priority: 'event'});
      } catch (e) {}
    }
    document.addEventListener('shiny:connected', rcmdrTourCheck);
    if (document.readyState === 'complete') {
      setTimeout(rcmdrTourCheck, 400);
    } else {
      window.addEventListener('load', function() {
        setTimeout(rcmdrTourCheck, 400);
      });
    }
    Shiny.addCustomMessageHandler('rcmdr-tour-highlight', function(message) {
      document.querySelectorAll('.rcmdr-tour-highlight').forEach(function(el) {
        el.classList.remove('rcmdr-tour-highlight');
      });
      var selector = message && message.selector;
      if (!selector) return;
      var target = document.querySelector(selector);
      if (!target) return;
      target.classList.add('rcmdr-tour-highlight');
      if (target.scrollIntoView) target.scrollIntoView({block: 'center'});
    });
    Shiny.addCustomMessageHandler('rcmdr-tour-clear', function(message) {
      document.querySelectorAll('.rcmdr-tour-highlight').forEach(function(el) {
        el.classList.remove('rcmdr-tour-highlight');
      });
    });
    Shiny.addCustomMessageHandler('rcmdr-tour-dismissed', function(message) {
      try {
        if (window.localStorage) {
          window.localStorage.setItem('rcmdr-tour-dismissed', '1');
        }
      } catch (e) {}
    });
