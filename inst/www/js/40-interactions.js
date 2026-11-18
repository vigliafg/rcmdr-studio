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
    // Accessible names for the widgets the libraries build without one ------
    // The visible <label> is not associated with the focusable element the
    // library creates inside the container, so point aria-labelledby at it.
    // The same pass adds the roles noUiSlider and Spectrum leave out.
    function rcmdrWidgetLabel(el) {
      var group = el.closest &&
        el.closest('.form-group, .shiny-input-container');
      var label = group && group.querySelector('label.control-label');
      return label && label.id ? label.id : null;
    }
    function rcmdrEnhanceWidgets(root) {
      if (!root || !root.querySelectorAll) return;
      Array.prototype.forEach.call(
        root.querySelectorAll(
          '.virtual-select .vscomp-ele-wrapper[role="combobox"]'
        ),
        function(el) {
          var id = rcmdrWidgetLabel(el);
          if (id && !el.getAttribute('aria-labelledby')) {
            el.setAttribute('aria-labelledby', id);
          }
        }
      );
      Array.prototype.forEach.call(
        root.querySelectorAll('.sw-no-ui-slider .noUi-handle'),
        function(el) {
          if (!el.getAttribute('role')) el.setAttribute('role', 'slider');
          el.setAttribute('aria-orientation', 'horizontal');
          var id = rcmdrWidgetLabel(el);
          if (id && !el.getAttribute('aria-labelledby')) {
            el.setAttribute('aria-labelledby', id);
          }
        }
      );
      Array.prototype.forEach.call(
        root.querySelectorAll('.sp-replacer'),
        function(el) {
          if (!el.getAttribute('role')) el.setAttribute('role', 'button');
          if (!el.hasAttribute('tabindex')) el.setAttribute('tabindex', '0');
          var id = rcmdrWidgetLabel(el);
          if (id && !el.getAttribute('aria-labelledby')) {
            el.setAttribute('aria-labelledby', id);
          }
        }
      );
    }
    window.rcmdrEnhanceWidgets = rcmdrEnhanceWidgets;
    function rcmdrEnhanceBound(event) {
      var target = event.target;
      var root = target && target.closest
        ? (target.closest('.form-group, .shiny-input-container') || target)
        : null;
      rcmdrEnhanceWidgets(root);
    }
    document.addEventListener('shiny:bound', rcmdrEnhanceBound);
    document.addEventListener('shiny:value', rcmdrEnhanceBound);
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', function() {
        rcmdrEnhanceWidgets(document);
      });
    } else {
      rcmdrEnhanceWidgets(document);
    }
    // The Spectrum replacer is a click target: give it the button keys.
    document.addEventListener('keydown', function(event) {
      if (event.key !== 'Enter' && event.key !== ' ') return;
      var replacer = event.target.closest && event.target.closest('.sp-replacer');
      if (!replacer) return;
      event.preventDefault();
      replacer.click();
    });
    // bslib shows a tooltip on focus but leaves Esc to the page: in a dialog
    // that would close the dialog.  Capture the key first, hide the bubble and
    // keep the focus on its trigger.
    document.addEventListener('keydown', function(event) {
      if (event.key !== 'Escape') return;
      var trigger = event.target.closest &&
        event.target.closest('.rcmdr-help-tip-trigger');
      if (!trigger) return;
      var tipId = trigger.getAttribute('aria-describedby');
      if (!tipId) return;
      var Tooltip = window.bootstrap && window.bootstrap.Tooltip;
      var instance = Tooltip && Tooltip.getInstance(trigger);
      if (instance) instance.hide();
      event.preventDefault();
      event.stopPropagation();
    }, true);
    // Focus only a field the user can actually see.  An invalid control can
    // live in a conditionalPanel that is still hidden, or in a panel whose
    // collapse has not finished: focusing it would do nothing and would move
    // the caret to an element with no box.  The candidates are checked after
    // the collapse transition, when the panel is really open.
    function rcmdrFocusFirst(candidates) {
      setTimeout(function() {
        var target = null;
        for (var i = 0; i < candidates.length; i += 1) {
          var el = candidates[i];
          if (el && el.getClientRects && el.getClientRects().length > 0) {
            target = el;
            break;
          }
        }
        if (!target) return;
        if (target.focus) target.focus();
        if (target.scrollIntoView) target.scrollIntoView({block: 'center'});
      }, 200);
    }
    window.rcmdrFocusField = function(id) {
      var el = document.getElementById(id);
      if (!el) el = document.querySelector('[id$="_' + id + '"]');
      if (!el) return false;
      el.classList.add('is-invalid');
      el.setAttribute('aria-invalid', 'true');
      rcmdrShowAccordions(el.closest('.modal') || document);
      // The collapse transition needs a frame before the field is focusable.
      rcmdrFocusFirst([el]);
      return false;
    };
    Shiny.addCustomMessageHandler('rcmdr-field-errors', function(message) {
      document.querySelectorAll('.is-invalid').forEach(function(el) {
        el.classList.remove('is-invalid');
        el.removeAttribute('aria-invalid');
      });
      var errors = (message && message.errors) || {};
      var candidates = [];
      Object.keys(errors).forEach(function(id) {
        var el = document.getElementById(id) ||
          document.querySelector('[id$="_' + id + '"]');
        if (!el) return;
        el.classList.add('is-invalid');
        el.setAttribute('aria-invalid', 'true');
        candidates.push(el);
      });
      if (candidates.length === 0) return;
      rcmdrShowAccordions(candidates[0].closest('.modal') || document);
      rcmdrFocusFirst(candidates);
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
