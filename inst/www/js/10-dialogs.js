    // Modal dialogs can be moved by dragging their header. Bootstrap 5 does not
    // ship a draggable modal any more, and the statistical dialogs are wide
    // enough that the data underneath is worth looking at while the dialog is
    // open. The offset is a transform, so Bootstrap keeps its own centring and
    // the dialog never leaves the window completely.
    (function () {
      var drag = null;

      function offsets(dialog) {
        var x = parseFloat(dialog.getAttribute('data-rcmdr-x'));
        var y = parseFloat(dialog.getAttribute('data-rcmdr-y'));
        return {
          x: isNaN(x) ? 0 : x,
          y: isNaN(y) ? 0 : y
        };
      }

      function place(dialog, x, y) {
        dialog.setAttribute('data-rcmdr-x', x);
        dialog.setAttribute('data-rcmdr-y', y);
        dialog.style.transform = 'translate(' + x + 'px,' + y + 'px)';
      }

      function reset(dialog) {
        dialog.style.transform = '';
        dialog.removeAttribute('data-rcmdr-x');
        dialog.removeAttribute('data-rcmdr-y');
      }

      function bounds(dialog, base) {
        var width = dialog.offsetWidth;
        return {
          minX: 40 - base.left - width,
          maxX: window.innerWidth - base.left - 40,
          minY: -base.top,
          maxY: window.innerHeight - base.top - 56
        };
      }

      function nearest(value, low, high) {
        if (low > high) {
          var swap = low;
          low = high;
          high = swap;
        }
        return Math.min(Math.max(value, low), high);
      }

      function baseOf(dialog, current) {
        var rect = dialog.getBoundingClientRect();
        return {
          left: rect.left - current.x,
          top: rect.top - current.y
        };
      }

      function interactive(target) {
        if (!target || !target.closest) return false;
        return !!target.closest(
          'button, a, input, select, textarea, label, [role=button], ' +
          '[data-bs-dismiss]'
        );
      }

      document.addEventListener('pointerdown', function (event) {
        if (event.button !== 0 || drag) return;
        var header = event.target.closest && event.target.closest('.modal-header');
        if (!header || interactive(event.target)) return;
        var dialog = header.closest('.modal-dialog');
        if (!dialog) return;
        var current = offsets(dialog);
        drag = {
          dialog: dialog,
          id: event.pointerId,
          startX: event.clientX,
          startY: event.clientY,
          from: current,
          base: baseOf(dialog, current)
        };
        if (header.setPointerCapture) {
          try { header.setPointerCapture(event.pointerId); } catch (e) {}
        }
        document.body.classList.add('rcmdr-dragging');
        event.preventDefault();
      });

      document.addEventListener('pointermove', function (event) {
        if (!drag || event.pointerId !== drag.id) return;
        var limit = bounds(drag.dialog, drag.base);
        var x = nearest(
          drag.from.x + (event.clientX - drag.startX), limit.minX, limit.maxX
        );
        var y = nearest(
          drag.from.y + (event.clientY - drag.startY), limit.minY, limit.maxY
        );
        place(drag.dialog, Math.round(x), Math.round(y));
        event.preventDefault();
      });

      function stop(event) {
        if (!drag) return;
        if (event && event.pointerId !== undefined && event.pointerId !== drag.id) {
          return;
        }
        drag = null;
        document.body.classList.remove('rcmdr-dragging');
      }

      document.addEventListener('pointerup', stop);
      document.addEventListener('pointercancel', stop);

      // Double click on the header puts the dialog back where it opened.
      document.addEventListener('dblclick', function (event) {
        var header = event.target.closest && event.target.closest('.modal-header');
        if (!header || interactive(event.target)) return;
        var dialog = header.closest('.modal-dialog');
        if (dialog) reset(dialog);
      });

      // Keep the header reachable when the window is resized.
      window.addEventListener('resize', function () {
        Array.prototype.forEach.call(
          document.querySelectorAll('.modal-dialog[data-rcmdr-x]'),
          function (dialog) {
            var current = offsets(dialog);
            var limit = bounds(dialog, baseOf(dialog, current));
            place(
              dialog,
              Math.round(nearest(current.x, limit.minX, limit.maxX)),
              Math.round(nearest(current.y, limit.minY, limit.maxY))
            );
          }
        );
      });
    })();
