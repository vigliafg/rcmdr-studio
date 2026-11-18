    // Data Studio selection --------------------------------------------------
    // Rows keeps the Wave 17 behaviour: click selects a row, Ctrl/Cmd-click
    // toggles.  Cells adds a rectangular range that the server turns into TSV.
    // The callback lives here rather than in a DT::JS string so the keyboard
    // handler and the clipboard handler are the same code for every redraw.
    (function() {
      var gridState = {
        table: null,
        mode: 'rows',
        anchor: null,
        end: null,
        dragging: false,
        selection: false
      };

      function rowsApi(table) {
        return table;
      }

      function cellIndex(table, node) {
        if (!node || !table || typeof table.cell !== 'function') return null;
        return table.cell(node).index();
      }

      function clearCellClasses(table) {
        if (!table) return;
        $(table.cells().nodes()).removeClass('rcmdr-cell-selected');
      }

      function renderedCells(table) {
        var out = [];
        $(table.cells().nodes()).each(function() {
          var index = cellIndex(table, this);
          if (index) out.push({node: this, row: index.row, column: index.column});
        });
        return out;
      }

      function paintRange(table, start, end) {
        if (!table || !start || !end) return;
        var r1 = Math.min(start.row, end.row);
        var r2 = Math.max(start.row, end.row);
        var c1 = Math.min(start.column, end.column);
        var c2 = Math.max(start.column, end.column);
        $(table.cells().nodes()).each(function() {
          var index = cellIndex(table, this);
          if (!index) return;
          var on = index.row >= r1 && index.row <= r2 &&
            index.column >= c1 && index.column <= c2;
          $(this).toggleClass('rcmdr-cell-selected', on);
        });
      }

      function columnNames(table, columns) {
        var names = [];
        var seen = {};
        columns.forEach(function(column) {
          if (seen[column]) return;
          seen[column] = true;
          var header = table.column(column).header();
          var name = header ? $(header).text().trim() : '';
          if (name) names.push(name);
        });
        return names;
      }

      function publishCells(table) {
        if (!table || !gridState.anchor || !gridState.end) return;
        var selected = [];
        var rows = [];
        var columns = [];
        var seenRows = {};
        var seenColumns = {};
        var r1 = Math.min(gridState.anchor.row, gridState.end.row);
        var r2 = Math.max(gridState.anchor.row, gridState.end.row);
        var c1 = Math.min(gridState.anchor.column, gridState.end.column);
        var c2 = Math.max(gridState.anchor.column, gridState.end.column);
        $(table.cells().nodes()).each(function() {
          var index = cellIndex(table, this);
          if (!index) return;
          if (index.row < r1 || index.row > r2 ||
              index.column < c1 || index.column > c2) return;
          selected.push(index);
          if (!seenRows[index.row]) {
            seenRows[index.row] = true;
            rows.push(index.row);
          }
          if (!seenColumns[index.column]) {
            seenColumns[index.column] = true;
            columns.push(index.column);
          }
        });
        if (!selected.length) return;
        rows.sort(function(a, b) { return a - b; });
        columns.sort(function(a, b) { return a - b; });
        var rowIds = rows.map(function(row) {
          var data = table.row(row).data() || [];
          return data[data.length - 1];
        });
        gridState.selection = true;
        Shiny.setInputValue('data_cell_selection', {
          row_ids: rowIds,
          columns: columnNames(table, columns),
          r1: r1 + 1,
          c1: c1 + 1,
          r2: r2 + 1,
          c2: c2 + 1
        }, {priority: 'event'});
      }

      function clearSelection(table) {
        var target = table || gridState.table;
        clearCellClasses(target);
        gridState.anchor = null;
        gridState.end = null;
        gridState.dragging = false;
        gridState.selection = false;
        if (target) {
          $(target.table().body()).find('tr.rcmdr-row-selected')
            .removeClass('rcmdr-row-selected');
        }
        Shiny.setInputValue('data_grid_selection', [], {priority: 'event'});
        Shiny.setInputValue('data_cell_selection', null, {priority: 'event'});
      }

      window.rcmdrGridSelection = function(table, mode) {
        gridState.table = table;
        gridState.mode = mode === 'cells' ? 'cells' : 'rows';
        gridState.anchor = null;
        gridState.end = null;
        gridState.dragging = false;
        gridState.selection = false;

        var $body = $(table.table().body());
        $body.off('.rcmdrGrid');
        $(document).off('mouseup.rcmdrGrid');

        if (gridState.mode === 'cells') {
          $body.on('mousedown.rcmdrGrid', 'td', function(event) {
            if ($(this).hasClass('dataTables_empty')) return;
            var index = cellIndex(table, this);
            if (!index) return;
            event.preventDefault();
            var keepAnchor = event.shiftKey && gridState.anchor;
            if (!keepAnchor) gridState.anchor = {row: index.row, column: index.column};
            gridState.end = {row: index.row, column: index.column};
            gridState.dragging = true;
            paintRange(table, gridState.anchor, gridState.end);
          });
          $body.on('mouseenter.rcmdrGrid', 'td', function() {
            if (!gridState.dragging) return;
            var index = cellIndex(table, this);
            if (!index) return;
            gridState.end = {row: index.row, column: index.column};
            paintRange(table, gridState.anchor, gridState.end);
          });
          $(document).on('mouseup.rcmdrGrid', function() {
            if (!gridState.dragging) return;
            gridState.dragging = false;
            publishCells(table);
          });
          return;
        }

        $body.on('click.rcmdrGrid', 'tr', function(event) {
          var $tr = $(this);
          if ($tr.hasClass('dataTables_empty')) return;
          if (event.ctrlKey || event.metaKey) {
            $tr.toggleClass('rcmdr-row-selected');
          } else {
            $body.find('tr.rcmdr-row-selected').removeClass('rcmdr-row-selected');
            $tr.addClass('rcmdr-row-selected');
          }
          var ids = [];
          table.rows('.rcmdr-row-selected').every(function() {
            var data = this.data() || [];
            ids.push(data[data.length - 1]);
          });
          Shiny.setInputValue('data_grid_selection', ids, {priority: 'event'});
        });
      };

      function inTextEntry(target) {
        if (!target) return false;
        var tag = target.tagName ? target.tagName.toLowerCase() : '';
        return tag === 'input' || tag === 'textarea' || tag === 'select' ||
          target.isContentEditable ||
          (target.closest && target.closest('.ace_editor'));
      }

      function stepCell(table, dRow, dColumn) {
        if (!gridState.anchor) return;
        var end = gridState.end || gridState.anchor;
        var cells = renderedCells(table);
        if (!cells.length) return;
        var rowValues = [];
        var columnValues = [];
        cells.forEach(function(cell) {
          if (rowValues.indexOf(cell.row) < 0) rowValues.push(cell.row);
          if (columnValues.indexOf(cell.column) < 0) columnValues.push(cell.column);
        });
        rowValues.sort(function(a, b) { return a - b; });
        columnValues.sort(function(a, b) { return a - b; });
        var rowAt = rowValues.indexOf(end.row);
        var columnAt = columnValues.indexOf(end.column);
        if (rowAt < 0) rowAt = 0;
        if (columnAt < 0) columnAt = 0;
        rowAt = Math.max(0, Math.min(rowValues.length - 1, rowAt + dRow));
        columnAt = Math.max(0, Math.min(columnValues.length - 1,
                                        columnAt + dColumn));
        gridState.end = {row: rowValues[rowAt], column: columnValues[columnAt]};
        paintRange(table, gridState.anchor, gridState.end);
        publishCells(table);
      }

      document.addEventListener('keydown', function(event) {
        if (gridState.mode !== 'cells' || inTextEntry(event.target)) return;
        if (document.querySelector('.modal.show')) return;
        var table = gridState.table;
        if (!table) return;

        if (event.key === 'Escape' && gridState.selection) {
          event.preventDefault();
          clearSelection(table);
          return;
        }
        if (event.shiftKey && !event.ctrlKey && !event.metaKey &&
            !event.altKey && /^Arrow(Up|Down|Left|Right)$/.test(event.key)) {
          if (!gridState.anchor) return;
          event.preventDefault();
          if (event.key === 'ArrowUp') stepCell(table, -1, 0);
          if (event.key === 'ArrowDown') stepCell(table, 1, 0);
          if (event.key === 'ArrowLeft') stepCell(table, 0, -1);
          if (event.key === 'ArrowRight') stepCell(table, 0, 1);
          return;
        }
        if ((event.ctrlKey || event.metaKey) && !event.altKey &&
            (event.key || '').toLowerCase() === 'c' && gridState.selection) {
          var copy = document.getElementById('copy_selection_shortcut');
          if (copy) {
            event.preventDefault();
            copy.click();
          }
        }
      });

      window.rcmdrCopyText = function(text) {
        var legacy = function() {
          var area = document.createElement('textarea');
          area.value = text;
          area.setAttribute('readonly', 'readonly');
          area.style.position = 'fixed';
          area.style.opacity = '0';
          document.body.appendChild(area);
          area.select();
          try {
            document.execCommand('copy');
          } catch (error) {
            // The notification on the server side still tells the user that
            // the selection exists; there is no second browser fallback.
          }
          document.body.removeChild(area);
        };
        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(text).catch(legacy);
        } else {
          legacy();
        }
      };
      Shiny.addCustomMessageHandler('rcmdr-copy', function(message) {
        window.rcmdrCopyText((message && message.text) || '');
      });
    })();
