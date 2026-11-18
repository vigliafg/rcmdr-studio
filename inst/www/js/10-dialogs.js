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
    // Resizable dialogs: the grip at the bottom-right changes width and
    // height, keyboard arrows do the same, and the result is sent to the
    // server so the same dialog id opens at the same size next time.
    (function () {
      var resize = null;

      function apply(dialog, width, height) {
        width = Math.max(360, Math.min(width, window.innerWidth - 24));
        height = Math.max(240, Math.min(height, window.innerHeight - 24));
        dialog.style.width = Math.round(width) + 'px';
        dialog.style.maxWidth = Math.round(width) + 'px';
        dialog.setAttribute('data-rcmdr-dialog-width', Math.round(width));
        dialog.style.setProperty('--rcmdr-dialog-height',
                                 Math.round(height) + 'px');
        dialog.setAttribute('data-rcmdr-dialog-height', Math.round(height));
        return {width: Math.round(width), height: Math.round(height)};
      }

      function current(dialog) {
        var content = dialog.querySelector('.modal-content');
        return {
          width: dialog.offsetWidth,
          height: content ? content.offsetHeight : dialog.offsetHeight
        };
      }

      function publish(dialog, size) {
        Shiny.setInputValue('dialog_geometry', {
          id: dialog.getAttribute('data-rcmdr-dialog-id') || '',
          width: size.width,
          height: size.height
        }, {priority: 'event'});
      }

      document.addEventListener('pointerdown', function (event) {
        var grip = event.target.closest &&
          event.target.closest('[data-rcmdr-dialog-resize]');
        if (!grip || event.button !== 0) return;
        var dialog = grip.closest('.modal-dialog');
        if (!dialog) return;
        var size = current(dialog);
        resize = {
          dialog: dialog,
          grip: grip,
          id: event.pointerId,
          startX: event.clientX,
          startY: event.clientY,
          width: size.width,
          height: size.height
        };
        if (grip.setPointerCapture) {
          try { grip.setPointerCapture(event.pointerId); } catch (e) {}
        }
        document.body.classList.add('rcmdr-resizing');
        event.preventDefault();
      });

      document.addEventListener('pointermove', function (event) {
        if (!resize || event.pointerId !== resize.id) return;
        apply(
          resize.dialog,
          resize.width + (event.clientX - resize.startX),
          resize.height + (event.clientY - resize.startY)
        );
        event.preventDefault();
      });

      function stop(event) {
        if (!resize) return;
        if (event && event.pointerId !== undefined &&
            event.pointerId !== resize.id) return;
        var dialog = resize.dialog;
        resize = null;
        document.body.classList.remove('rcmdr-resizing');
        publish(dialog, current(dialog));
      }

      document.addEventListener('pointerup', stop);
      document.addEventListener('pointercancel', stop);

      document.addEventListener('keydown', function (event) {
        var grip = event.target.closest &&
          event.target.closest('[data-rcmdr-dialog-resize]');
        if (!grip) return;
        var dialog = grip.closest('.modal-dialog');
        if (!dialog) return;
        var size = current(dialog);
        var step = event.shiftKey ? 60 : 20;
        var handled = true;
        if (event.key === 'ArrowRight') size.width += step;
        else if (event.key === 'ArrowLeft') size.width -= step;
        else if (event.key === 'ArrowDown') size.height += step;
        else if (event.key === 'ArrowUp') size.height -= step;
        else handled = false;
        if (!handled) return;
        event.preventDefault();
        publish(dialog, apply(dialog, size.width, size.height));
      });
    })();
