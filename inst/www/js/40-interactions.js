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
    // Busy state -----------------------------------------------------------
    // The status bar badge is visual; this live region is what a screen
    // reader hears while a command runs.  `aria-busy` keeps the rest quiet.
    Shiny.addCustomMessageHandler('rcmdr-busy', function(message) {
      var live = document.getElementById('rcmdr-live-status');
      var main = document.getElementById('main-content') || document.body;
      var busy = !!(message && message.busy);
      if (live) live.textContent = busy ? (message.message || '') : '';
      if (!main) return;
      if (busy) main.setAttribute('aria-busy', 'true');
      else main.removeAttribute('aria-busy');
    });

    // Notifications --------------------------------------------------------
    // Shiny stacks every notification it is given.  Keep the newest three and
    // give the panel the live semantics it lacks; the DOM is Shiny's own.
    function rcmdrLimitNotifications(panel) {
      var notes = panel.querySelectorAll('.shiny-notification');
      for (var i = 0; i < notes.length - 3; i += 1) {
        var close = notes[i].querySelector('.shiny-notification-close');
        if (close) close.click(); else notes[i].remove();
      }
    }
    function rcmdrWatchNotifications() {
      var panel = document.getElementById('shiny-notification-panel');
      if (!panel || panel.getAttribute('data-rcmdr-watched') === '1') return;
      panel.setAttribute('data-rcmdr-watched', '1');
      panel.setAttribute('role', 'status');
      panel.setAttribute('aria-live', 'polite');
      panel.setAttribute('aria-atomic', 'false');
      var observer = new MutationObserver(function() {
        rcmdrLimitNotifications(panel);
      });
      observer.observe(panel, {childList: true});
      rcmdrLimitNotifications(panel);
    }
    document.addEventListener('shiny:connected', function() {
      // The panel is created with the first notification, not at startup.
      var bodyObserver = new MutationObserver(function() {
        if (document.getElementById('shiny-notification-panel')) {
          bodyObserver.disconnect();
          rcmdrWatchNotifications();
        }
      });
      bodyObserver.observe(document.body, {childList: true});
      rcmdrWatchNotifications();
    });

    // Split panes ----------------------------------------------------------
    // The separator is a real focus target: the arrows move it, Home/End go to
    // the edges, Enter/Space (and a double click) restore the default.  A
    // pointer drag writes the same share.  The server persists the value only
    // on release, so a drag does not flood the websocket.
    function splitIsHorizontal(divider) {
      var container = divider.closest('.rcmdr-splitter');
      if (!container) return true;
      return container.getAttribute('data-rcmdr-split-orientation') !== 'vertical';
    }
    function splitSize(divider) {
      var container = divider.closest('.rcmdr-splitter');
      if (!container) return 0;
      var rect = container.getBoundingClientRect();
      return splitIsHorizontal(divider) ? rect.width : rect.height;
    }
    function splitBounds(divider) {
      var size = splitSize(divider);
      if (!size) return null;
      var dividerSize = splitIsHorizontal(divider)
        ? divider.getBoundingClientRect().width
        : divider.getBoundingClientRect().height;
      var minFirst = parseFloat(divider.getAttribute('data-rcmdr-split-min')) || 0;
      var minSecond = parseFloat(divider.getAttribute('data-rcmdr-split-min-second')) || 0;
      var low = (minFirst / size) * 100;
      var high = 100 - ((minSecond + dividerSize) / size) * 100;
      if (!isFinite(low)) low = 5;
      if (!isFinite(high) || high <= low) {
        low = 5; high = 95;
      }
      return {low: low, high: high};
    }
    function splitSet(divider, percent, notify) {
      var container = divider.closest('.rcmdr-splitter');
      if (!container) return;
      var bounds = splitBounds(divider);
      var value = Number(percent);
      if (!isFinite(value)) return;
      if (bounds) value = Math.min(bounds.high, Math.max(bounds.low, value));
      value = Math.min(95, Math.max(5, value));
      container.style.setProperty('--rcmdr-split-first', value.toFixed(2) + '%');
      divider.setAttribute('aria-valuenow', String(Math.round(value)));
      divider.setAttribute('aria-valuetext', Math.round(value) + '%');
      if (bounds) {
        divider.setAttribute('aria-valuemin', String(Math.round(bounds.low)));
        divider.setAttribute('aria-valuemax', String(Math.round(bounds.high)));
      }
      if (notify) {
        var input = divider.getAttribute('data-rcmdr-split-input');
        if (input && window.Shiny && window.Shiny.setInputValue) {
          window.Shiny.setInputValue(input, value / 100, {priority: 'event'});
        }
      }
    }
    function splitReset(divider, notify) {
      var fallback = parseFloat(divider.getAttribute('data-rcmdr-split-default'));
      splitSet(divider, isFinite(fallback) ? fallback : 50, notify);
    }
    function splitInit(divider) {
      var bounds = splitBounds(divider);
      if (bounds) {
        divider.setAttribute('aria-valuemin', String(Math.round(bounds.low)));
        divider.setAttribute('aria-valuemax', String(Math.round(bounds.high)));
      }
    }
    function splitDividers(root) {
      return (root || document).querySelectorAll('.rcmdr-splitter-divider');
    }
    function splitInitAll() {
      Array.prototype.forEach.call(splitDividers(), splitInit);
    }
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', splitInitAll);
    } else {
      splitInitAll();
    }
    document.addEventListener('shiny:connected', splitInitAll);
    window.addEventListener('resize', splitInitAll);

    var splitDrag = null;
    document.addEventListener('pointerdown', function(event) {
      if (event.button !== 0) return;
      var divider = event.target.closest &&
        event.target.closest('.rcmdr-splitter-divider');
      if (!divider) return;
      splitDrag = {
        divider: divider,
        pointerId: event.pointerId,
        moved: false,
        last: null
      };
      try { divider.setPointerCapture(event.pointerId); } catch (e) {}
      document.body.classList.add('rcmdr-splitter-dragging');
      event.preventDefault();
    });
    document.addEventListener('pointermove', function(event) {
      if (!splitDrag || event.pointerId !== splitDrag.pointerId) return;
      var divider = splitDrag.divider;
      var container = divider.closest('.rcmdr-splitter');
      if (!container) return;
      var rect = container.getBoundingClientRect();
      var horizontal = splitIsHorizontal(divider);
      var pos = horizontal ? event.clientX - rect.left : event.clientY - rect.top;
      var size = horizontal ? rect.width : rect.height;
      var dividerSize = horizontal
        ? divider.getBoundingClientRect().width
        : divider.getBoundingClientRect().height;
      if (size <= 0) return;
      var percent = ((pos - dividerSize / 2) / size) * 100;
      if (splitDrag.last !== null && Math.abs(percent - splitDrag.last) < 0.1) return;
      splitDrag.last = percent;
      splitDrag.moved = true;
      splitSet(divider, percent, false);
      event.preventDefault();
    });
    function splitEnd(event) {
      if (!splitDrag) return;
      if (event && event.pointerId !== splitDrag.pointerId) return;
      var divider = splitDrag.divider;
      var moved = splitDrag.moved;
      try { divider.releasePointerCapture(splitDrag.pointerId); } catch (e) {}
      splitDrag = null;
      document.body.classList.remove('rcmdr-splitter-dragging');
      if (moved) {
        splitSet(divider, parseFloat(divider.getAttribute('aria-valuenow')), true);
      }
    }
    document.addEventListener('pointerup', splitEnd);
    document.addEventListener('pointercancel', splitEnd);

    var splitKeyPending = null;
    document.addEventListener('keydown', function(event) {
      var divider = event.target.closest &&
        event.target.closest('.rcmdr-splitter-divider');
      if (!divider) return;
      var horizontal = splitIsHorizontal(divider);
      var current = parseFloat(divider.getAttribute('aria-valuenow'));
      if (!isFinite(current)) current = 50;
      var step = event.shiftKey ? 8 : 2;
      var next = null;
      if (horizontal && event.key === 'ArrowLeft') next = current - step;
      else if (horizontal && event.key === 'ArrowRight') next = current + step;
      else if (!horizontal && event.key === 'ArrowUp') next = current - step;
      else if (!horizontal && event.key === 'ArrowDown') next = current + step;
      else if (event.key === 'Home') next = 0;
      else if (event.key === 'End') next = 100;
      else if (event.key === 'Enter' || event.key === ' ' ||
               event.key === 'Spacebar') next = 'reset';
      if (next === null) return;
      event.preventDefault();
      event.stopPropagation();
      if (next === 'reset') splitReset(divider, false);
      else splitSet(divider, next, false);
      splitKeyPending = divider;
    }, true);
    // The visual move is immediate; only the key release reaches the server,
    // so a held arrow key does not rewrite the preferences file on repeat.
    document.addEventListener('keyup', function(event) {
      if (!splitKeyPending) return;
      var divider = splitKeyPending;
      splitKeyPending = null;
      var current = parseFloat(divider.getAttribute('aria-valuenow'));
      splitSet(divider, isFinite(current) ? current : 50, true);
    }, true);

    document.addEventListener('dblclick', function(event) {
      var divider = event.target.closest &&
        event.target.closest('.rcmdr-splitter-divider');
      if (!divider) return;
      event.preventDefault();
      splitReset(divider, true);
    });
