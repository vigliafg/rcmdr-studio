    // Data Studio selection --------------------------------------------------
    // Rows keeps the Wave 17 behaviour: click selects a row, Ctrl/Cmd-click
    // toggles.  Cells adds a rectangular range that the server turns into TSV.
    // The callback lives here rather than in a DT::JS string so the keyboard
    // handler and the clipboard handler are the same code for every redraw.
    (function() {
      var gridState = {
        table: null,
        mode: 'rows',
        dataset: '',
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
          $(target.table().body()).find('tr.rcmdr-row-active')
            .removeClass('rcmdr-row-active');
        }
        Shiny.setInputValue('data_grid_selection', [], {priority: 'event'});
        Shiny.setInputValue('data_cell_selection', null, {priority: 'event'});
      }

      function visibleColumns(table) {
        var columns = [];
        var widths = [];
        $(table.table().header()).find('th').each(function() {
          if (!$(this).is(':visible')) return;
          var name = $(this).text().trim();
          if (!name) return;
          columns.push(name);
          widths.push(Math.round(this.getBoundingClientRect().width));
        });
        return {columns: columns, widths: widths};
      }

      function publishWidths(table, dataset) {
        if (!table || !dataset) return;
        var sizes = visibleColumns(table);
        if (!sizes.columns.length) return;
        Shiny.setInputValue('data_column_widths', {
          dataset: dataset,
          columns: sizes.columns,
          widths: sizes.widths
        }, {priority: 'event'});
      }

      function setupColumnResize(table, dataset, resizeLabel) {
        var header = table.table().header();
        if (!header) return;
        $(header).find('.rcmdr-col-resizer').remove();
        $(header).find('th').each(function() {
          if (!$(this).is(':visible')) return;
          var name = $(this).text().trim();
          var width = Math.round(this.getBoundingClientRect().width);
          var handle = document.createElement('span');
          handle.className = 'rcmdr-col-resizer';
          // The grip is a real control: a pointer drag and the arrow keys do
          // the same thing, and the width is exposed as a range value.
          handle.setAttribute('role', 'separator');
          handle.setAttribute('tabindex', '0');
          handle.setAttribute('aria-orientation', 'vertical');
          handle.setAttribute('aria-label',
            (resizeLabel || 'Resize column') + (name ? ' ' + name : ''));
          handle.setAttribute('aria-valuemin', '40');
          handle.setAttribute('aria-valuemax', '1200');
          handle.setAttribute('aria-valuenow', String(width));
          handle.setAttribute('aria-valuetext', width + ' px');
          handle.setAttribute('data-rcmdr-default-width', String(width));
          this.appendChild(handle);
        });
        $(header).off('.rcmdrResize');
        $(header).on('click.rcmdrResize', '.rcmdr-col-resizer', function(event) {
          event.preventDefault();
          event.stopPropagation();
        });
        $(header).on('keydown.rcmdrResize', '.rcmdr-col-resizer',
          function(event) {
            var key = event.key;
            if (key !== 'ArrowLeft' && key !== 'ArrowRight' &&
                key !== 'Home') return;
            event.preventDefault();
            event.stopPropagation();
            var th = this.parentNode;
            var current = th.getBoundingClientRect().width;
            var width = key === 'Home'
              ? parseFloat(this.getAttribute('data-rcmdr-default-width')) || current
              : Math.max(40, Math.min(1200,
                  current + (key === 'ArrowRight' ? 16 : -16)));
            table.table().node().style.tableLayout = 'fixed';
            th.style.width = width + 'px';
            th.style.minWidth = width + 'px';
            this.setAttribute('aria-valuenow', String(Math.round(width)));
            this.setAttribute('aria-valuetext', Math.round(width) + ' px');
          });
        $(header).on('keyup.rcmdrResize', '.rcmdr-col-resizer', function() {
          publishWidths(table, dataset);
        });
        $(header).on('pointerdown.rcmdrResize', '.rcmdr-col-resizer',
          function(event) {
            if (event.button !== 0) return;
            event.preventDefault();
            event.stopPropagation();
            var th = this.parentNode;
            var startX = event.clientX;
            var startWidth = th.getBoundingClientRect().width;
            var pointerId = event.pointerId;
            var node = table.table().node();
            node.style.tableLayout = 'fixed';
            document.body.classList.add('rcmdr-col-resizing');
            $(document).off('pointermove.rcmdrResize pointerup.rcmdrResize ' +
                            'pointercancel.rcmdrResize');
            $(document).on('pointermove.rcmdrResize', function(move) {
              if (move.pointerId !== pointerId) return;
              var width = Math.max(40,
                Math.min(1200, startWidth + move.clientX - startX));
              th.style.width = width + 'px';
              th.style.minWidth = width + 'px';
            });
            $(document).on('pointerup.rcmdrResize pointercancel.rcmdrResize',
              function() {
                $(document).off('.rcmdrResize');
                document.body.classList.remove('rcmdr-col-resizing');
                publishWidths(table, dataset);
              });
          });
      }

      function renderedRows(table) {
        return $(table.table().body()).find('tr').filter(function() {
          return !$(this).hasClass('dataTables_empty');
        }).toArray();
      }

      function paintActiveRow(table, row) {
        $(table.table().body()).find('tr.rcmdr-row-active')
          .removeClass('rcmdr-row-active');
        if (!row) return;
        $(row).addClass('rcmdr-row-active');
        if (row.scrollIntoView) row.scrollIntoView({block: 'nearest'});
      }

      function emitRowSelection(table, $tr, additive) {
        if (!additive) {
          $(table.table().body()).find('tr.rcmdr-row-selected')
            .removeClass('rcmdr-row-selected');
        }
        if (additive && $tr.hasClass('rcmdr-row-selected')) {
          $tr.removeClass('rcmdr-row-selected');
        } else {
          $tr.addClass('rcmdr-row-selected');
        }
        var ids = [];
        table.rows('.rcmdr-row-selected').every(function() {
          var data = this.data() || [];
          ids.push(data[data.length - 1]);
        });
        Shiny.setInputValue('data_grid_selection', ids, {priority: 'event'});
      }

      function setupGridKeyboard(table, gridLabel) {
        var node = table.table().node();
        if (!node) return;
        // DT renders a plain table.  One tab stop on the table is enough to
        // move a row cursor and to start a selection without a mouse; the
        // server announces the result like a click does.
        node.setAttribute('tabindex', '0');
        node.setAttribute('aria-label', gridLabel || 'Data grid');
        $(node).off('.rcmdrGridKeys');
        $(node).on('keydown.rcmdrGridKeys', function(event) {
          if (document.querySelector('.modal.show')) return;
          var key = event.key;
          var rows = renderedRows(table);
          if (!rows.length) return;
          var active = $(node).find('tr.rcmdr-row-active')[0] || null;
          var index = active ? rows.indexOf(active) : -1;

          if (!event.shiftKey &&
              (key === 'ArrowDown' || key === 'ArrowUp')) {
            event.preventDefault();
            var step = key === 'ArrowDown' ? 1 : -1;
            index = index < 0
              ? 0
              : Math.max(0, Math.min(rows.length - 1, index + step));
            paintActiveRow(table, rows[index]);
            if (gridState.mode === 'cells') {
              var cell = $(rows[index]).find('td').get(0);
              var cellIndexValue = cell ? cellIndex(table, cell) : null;
              if (cellIndexValue) {
                var column = gridState.end
                  ? gridState.end.column
                  : cellIndexValue.column;
                gridState.anchor = {row: cellIndexValue.row, column: column};
                gridState.end = {row: cellIndexValue.row, column: column};
                paintRange(table, gridState.anchor, gridState.end);
                publishCells(table);
              }
            }
            return;
          }

          if ((key === 'Enter' || key === ' ' || key === 'Spacebar') &&
              active) {
            event.preventDefault();
            if (gridState.mode === 'cells') {
              var first = $(active).find('td').get(0);
              var firstIndex = first ? cellIndex(table, first) : null;
              if (firstIndex) {
                gridState.anchor = {row: firstIndex.row,
                                    column: firstIndex.column};
                gridState.end = {row: firstIndex.row,
                                 column: firstIndex.column};
                paintRange(table, gridState.anchor, gridState.end);
                publishCells(table);
              }
            } else {
              emitRowSelection(table, $(active),
                               event.ctrlKey || event.metaKey);
            }
          }
        });
      }

      window.rcmdrGridSelection = function(table, mode, dataset, gridLabel,
                                           resizeLabel) {
        gridState.table = table;
        gridState.mode = mode === 'cells' ? 'cells' : 'rows';
        gridState.dataset = dataset || '';
        setupColumnResize(table, gridState.dataset, resizeLabel);
        setupGridKeyboard(table, gridLabel);
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
          paintActiveRow(table, this);
          emitRowSelection(table, $tr, event.ctrlKey || event.metaKey);
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
