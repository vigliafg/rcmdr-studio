    // Modeless panels do not move focus when they open.  The trigger is kept
    // so the close button can return focus to the menu item that opened it.
    (function () {
      var trigger = null;
      Shiny.addCustomMessageHandler('rcmdr-modeless', function (message) {
        if (message && message.open) {
          trigger = document.activeElement;
        } else {
          trigger = null;
        }
      });
      function closeAndReturn() {
        var previous = trigger;
        trigger = null;
        if (previous && previous.focus) {
          window.setTimeout(function () { previous.focus(); }, 0);
        }
      }
      document.addEventListener('click', function (event) {
        var target = event.target;
        if (!target || !target.closest || !target.closest('#modeless_close')) {
          return;
        }
        closeAndReturn();
      }, true);
      // One Escape, one level.  A capture listener runs before Bootstrap and
      // before the bubble handlers; if an inner layer (tooltip, menu, cell
      // selection) already claimed the key, `defaultPrevented` says so and
      // this layer stays open.  With a dialog on top, the dialog is the
      // level: closing the panel underneath it would be a surprise.
      document.addEventListener('keydown', function (event) {
        if (event.key !== 'Escape' || event.defaultPrevented) return;
        if (event.altKey || event.ctrlKey || event.metaKey) return;
        if (document.querySelector('.modal.show')) return;
        var panel = document.querySelector('.rcmdr-modeless-panel');
        var close = document.getElementById('modeless_close');
        if (!panel || !close) return;
        event.preventDefault();
        close.click();
      }, true);
    })();
