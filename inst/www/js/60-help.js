    document.addEventListener('click', function(event) {
      var target = event.target;
      if (!target || !target.closest) return;
      var example = target.closest('[data-help-example]');
      if (example) {
        event.preventDefault();
        Shiny.setInputValue('help_example_run', {
          topic: example.getAttribute('data-help-example'),
          index: parseInt(example.getAttribute('data-help-example-index') || '1', 10)
        }, {priority: 'event'});
        return;
      }
      var exampleInsert = target.closest('[data-help-example-insert]');
      if (exampleInsert) {
        event.preventDefault();
        Shiny.setInputValue('help_example_insert',
          exampleInsert.getAttribute('data-help-example-insert'),
          {priority: 'event'});
        return;
      }
      var dialogLink = target.closest('[data-help-dialog]');
      if (dialogLink) {
        event.preventDefault();
        Shiny.setInputValue('help_open_dialog',
          dialogLink.getAttribute('data-help-dialog'), {priority: 'event'});
        return;
      }
      var help = target.closest('[data-help-topic]');
      if (help) {
        event.preventDefault();
        Shiny.setInputValue('help_open',
          help.getAttribute('data-help-topic'), {priority: 'event'});
        var pane = document.getElementById('help_topic_pane');
        if (pane) pane.focus();
        return;
      }
      var copy = target.closest('[data-rcmdr-copy]');
      if (copy) {
        event.preventDefault();
        rcmdrCopy(copy.getAttribute('data-rcmdr-copy'));
        return;
      }
    }, true);
