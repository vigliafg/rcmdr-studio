    function rcmdrRunChunk() {
      var element = document.querySelector('#script_editor_ui .ace_editor');
      if (!element) return;
      var editor = ace.edit(element);
      var position = editor.getCursorPosition();
      Shiny.setInputValue('run_chunk_at',
        {row: position.row, column: position.column}, {priority: 'event'});
    }
    window.rcmdrReportGoto = function(line) {
      var element = document.querySelector('#report_editor_ui .ace_editor');
      if (!element) return false;
      var editor = ace.edit(element);
      editor.gotoLine(line + 1, 0);
      editor.focus();
      return false;
    };
    window.rcmdrScriptGoto = function(line) {
      var element = document.querySelector('#script_editor_ui .ace_editor');
      if (!element) return false;
      var editor = ace.edit(element);
      editor.gotoLine(line + 1, 0);
      editor.focus();
      return false;
    };
    window.rcmdrScriptRunAt = function(inputId) {
      var element = document.querySelector('#script_editor_ui .ace_editor');
      if (!element) return false;
      var editor = ace.edit(element);
      var position = editor.getCursorPosition();
      Shiny.setInputValue(inputId,
        {row: position.row, column: position.column, nonce: Math.random()},
        {priority: 'event'});
      return false;
    };
    function rcmdrScriptEditor() {
      var element = document.querySelector('#script_editor_ui .ace_editor');
      if (!element) return null;
      var editor = ace.edit(element);
      rcmdrApplyCompletions(editor);
      return editor;
    }
    function rcmdrApplyCompletions(editor) {
      if (!editor || !window.rcmdrCompletionWords) return;
      try { ace.require('ace/ext/language_tools'); } catch (e) { return; }
      editor.setOptions({enableBasicAutocompletion: true, enableLiveAutocompletion: true});
      if (editor.__rcmdrCompleter === window.rcmdrCompletionWords) return;
      editor.__rcmdrCompleter = window.rcmdrCompletionWords;
      editor.completers = [{
        getCompletions: function(editor, session, pos, prefix, callback) {
          callback(null, window.rcmdrCompletionWords.map(function(word) {
            return {name: word, value: word, score: 1000, meta: 'R'};
          }));
        }
      }].concat(editor.completers || []);
    }
    window.rcmdrScriptFind = function() {
      var editor = rcmdrScriptEditor();
      if (!editor) return false;
      var input = document.getElementById('script_find');
      var query = input ? input.value : '';
      if (!query) return false;
      editor.find(query, {
        backwards: false, wrap: true, caseSensitive: false,
        wholeWord: false, regExp: false
      });
      editor.focus();
      return false;
    };
    window.rcmdrScriptReplace = function(all) {
      var editor = rcmdrScriptEditor();
      if (!editor) return false;
      var findInput = document.getElementById('script_find');
      var replaceInput = document.getElementById('script_replace');
      var query = findInput ? findInput.value : '';
      var replacement = replaceInput ? replaceInput.value : '';
      if (!query) return false;
      if (all) {
        editor.replaceAll(replacement, {regExp: false});
      } else {
        editor.find(query, {
          backwards: false, wrap: true, caseSensitive: false,
          wholeWord: false, regExp: false
        });
        editor.replace(replacement);
      }
      editor.focus();
      return false;
    };
    window.rcmdrScriptEditor = rcmdrScriptEditor;
    Shiny.addCustomMessageHandler('rcmdr-completions', function(words) {
      window.rcmdrCompletionWords = words || [];
      rcmdrApplyCompletions(rcmdrScriptEditor());
    });
    Shiny.addCustomMessageHandler('rcmdr-bind-script', function(message) {
      rcmdrScriptEditor();
    });
