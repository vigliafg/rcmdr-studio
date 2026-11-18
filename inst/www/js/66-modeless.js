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
      document.addEventListener('click', function (event) {
        var target = event.target;
        if (!target || !target.closest || !target.closest('#modeless_close')) {
          return;
        }
        var previous = trigger;
        trigger = null;
        if (previous && previous.focus) {
          window.setTimeout(function () { previous.focus(); }, 0);
        }
      }, true);
    })();
