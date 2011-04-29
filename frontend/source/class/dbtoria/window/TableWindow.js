/* ************************************************************************

  DbToRia - Database to Rich Internet Application

  http://www.dbtoria.org

   Copyright:
    2009 David Angleitner, Switzerland
    2011 Oetiker+Partner AG, Olten, Switzerland

   License:
    GPL: http://www.gnu.org/licenses/gpl-2.0.html

   Authors:
    * David Angleitner
    * Fritz Zaucker

************************************************************************ */

/*
 * TODOs:
 *   - show number of filtered rows in table legend, e.g.  x (y) rows
 *   - change appearance of filter button when filter active
 *   - perhaps integrate filter configuration into TableWindow instead of
 *     using a separate window
 */

/* ************************************************************************

#asset(dbtoria/*)
#asset(qx/icon/${qx.icontheme}/16/mimetypes/text-plain.png)
#asset(qx/icon/${qx.icontheme}/16/actions/contact-new.png)
#asset(qx/icon/${qx.icontheme}/16/actions/edit-delete.png)
#asset(qx/icon/${qx.icontheme}/16/actions/view-refresh.png)
#asset(qx/icon/${qx.icontheme}/16/actions/document-save-as.png)
#asset(qx/icon/${qx.icontheme}/16/actions/document-print.png)
#asset(qx/icon/${qx.icontheme}/16/actions/system-search.png)
#asset(qx/icon/${qx.icontheme}/16/actions/edit-copy.png)
#asset(qx/icon/${qx.icontheme}/16/apps/utilities-text-editor.png)

************************************************************************ */

/**
 * This class provides the view for a specific table.
 *
 * It displays a traditional table at first. On clicking on a row it opens a
 * form for data editing. This window also allows for searching, creation and
 * deletion of entries.
 */
qx.Class.define("dbtoria.window.TableWindow", {
    extend : dbtoria.window.DesktopWindow,
        construct : function(tableId, tableName, viewMode) {
        this.__tableName = tableName;
        this.__tableId   = tableId;
        this.base(arguments);
        this.set({
            contentPadding : 0,
            layout         : new qx.ui.layout.VBox().set({ separator: "separator-vertical"}),
            width          : 800,
            height         : 500,
            loading        : true
        });
        if (viewMode) {
            this.setCaption(this.tr('View: %1', this.__tableName));
        }
        else {
            this.setCaption(this.tr('Table: %1', this.__tableName));
        }

        this.__rpc = dbtoria.io.remote.Rpc.getInstance();
        this.__buildUi(tableId, viewMode);
        this.__recordEdit = new dbtoria.window.RecordEdit(tableId, tableName, viewMode);
        this.__recordEdit.addListener('navigation', this.__navigation, this);
        this.__recordEdit.addListener('refresh',    this.__refresh, this);
        this.__recordEdit.addListener('undo',       this.__undo, this);
        this.__recordEdit.addListener('done',       this.__done, this);
        this.open();
    },

    members : {
        __table:      null,
        __tbEdit:     null,
        __tbDelete:   null,
        __tbDup:      null,
        __tbNew:      null,
        __currentId:  null,
        __tableName:  null,
        __tableId:    null,
        __columns:    null,
        __recordEdit: null,
        __rpc:        null,
        __lastRow:    null,
        __lastId:     null,
        __newRow:     null,

        __refresh : function(e) {
            this.__done();
            this.__table.getTableModel().reloadData();
        },

        __undo : function(e) {
            this.debug('__undo(): lastId='+this.__lastId+', lastRow='+this.__lastRow);
            var row = this.__lastRow;
            var sm     = this.__table.getSelectionModel();
            sm.setSelectionInterval(row, row);
        },

        __done : function(e) {
            this.__lastRow = this.__newRow;
            this.__newRow  = null;
            this.debug('__done(): lastRow='+this.__lastRow);
        },

        __navigation : function(e) {
            var target = e.getData();
            var sm     = this.__table.getSelectionModel();
            var tm     = this.__table.getTableModel();
            var selection = sm.getSelectedRanges()[0];
            var row;
            if (selection == undefined || selection == null) {
                row = 0; // FIX ME: is this sensible?
            }
            else {
                row    = sm.getSelectedRanges()[0].minIndex;
            }

            // switch record
            var maxRow = tm.getRowCount();
            this.debug('__navigation(): target='+target+', row='+row+', maxRow='+maxRow);
            switch (target) {
            case 'first':
                row = 0;
                break;
            case 'back':
                if (row>0) {
                    row--;
                }
                break;
            case 'next':
                if (row<maxRow-1) {
                    row++;
                }
                break;
            case 'last':
                row = maxRow-1;
                break;
            case 'new':
                this.__newRecord();
                return;
                break;
            case 'close':
                return;
                break;
            }

            // switch
            sm.setSelectionInterval(row, row);
            this.__table.scrollCellVisible(0, row);
//            this.__editRecord(row);

        },


        /**
         * Display a table overview with data
         *
         * @return {void}
         */
      __buildUi : function(tableId, viewMode) {
            var toolbar = new qx.ui.toolbar.ToolBar();
            var newButton = this.__tbNew = new qx.ui.toolbar.Button(this.tr("New"), "icon/16/actions/contact-new.png");
            var editButton = this.__tbEdit = new qx.ui.toolbar.Button(this.tr("Edit"), "icon/16/apps/utilities-text-editor.png").set({enabled: false});
            var dupButton = this.__tbDup = new qx.ui.toolbar.Button(this.tr("Copy"), "icon/16/actions/edit-copy.png").set({enabled: false});
            var deleteButton = this.__tbDelete = new qx.ui.toolbar.Button(this.tr("Delete"), "icon/16/actions/edit-delete.png").set({enabled: false});
            var refreshButton = new qx.ui.toolbar.Button(this.tr("Refresh"), "icon/16/actions/view-refresh.png");
            var exportButton = new qx.ui.toolbar.Button(this.tr("Export"), "icon/16/actions/document-save-as.png").set({enabled: false});
            var printButton = new qx.ui.toolbar.Button(this.tr("Print"), "icon/16/actions/document-print.png").set({enabled: false});
            var filterButton = new qx.ui.toolbar.CheckBox(this.tr("Search"), "icon/16/actions/system-search.png");

            if (!viewMode) {
                newButton.addListener('execute', this.__newRecord, this);
                toolbar.add(newButton);

                editButton.addListener('execute', this.__editRecord, this);
                toolbar.add(editButton);

                toolbar.add(dupButton);

                deleteButton.addListener('execute', this.__deleteRecord, this);
                toolbar.add(deleteButton);
            }

            toolbar.addSpacer();

            refreshButton.addListener('execute', this.__refresh, this);
            toolbar.add(refreshButton);

            toolbar.add(exportButton);
            toolbar.add(printButton);

            filterButton.addListener('execute', qx.lang.Function.bind(this.__filterTable, this), this);
            toolbar.add(filterButton);

            this.add(toolbar);
            var that = this;
            this.__rpc.callAsyncSmart(function(ret){
                var columns = ret.columns;
                that.__columns = columns;
                var tableId = ret.tableId;
                var columnIds = [];
                var columnLabels = {};
                var i, nCols = columns.length;
                for (i=0; i<nCols; i++){
                    columnIds.push(columns[i].id);
                    columnLabels[columns[i].id] = columns[i].name;
                }
                var model = new dbtoria.data.RemoteTableModel(tableId,columnIds,columnLabels);
                that.__table = new dbtoria.ui.table.Table(model);
                if (!viewMode) {
                    that.__table.getSelectionModel().addListener('changeSelection',that.__switchRecord, that);
                    that.__table.addListener("cellDblclick", that.__editRecord, that);
                }
                for (i=0; i<nCols; i++){
                    that.__table.setContextMenuHandler(i, that.__contextMenuHandler, that);
                }
                that.add(that.__table, { flex : 1 });
                that.setLoading(false);
            },'getListView',tableId);
        },

        __contextMenuHandler: function(col, row, table, dataModel, contextMenu) {
            var editEntry   = new qx.ui.menu.Button(this.tr("Edit"));
            editEntry.addListener("execute", this.__editRecord, this);
            var deleteEntry = new qx.ui.menu.Button(this.tr("Delete")).set({enabled: false});
            deleteEntry.addListener("execute", this.__deleteRecord, this);
            var dupEntry = new qx.ui.menu.Button(this.tr("Copy")).set({enabled: false});
            dupEntry.addListener("execute", this.__dupRecord, this);
            contextMenu.add(editEntry);
            contextMenu.add(deleteEntry);
            contextMenu.add(dupEntry);

            return true;
        },


        __deleteRecord : function(e) {
            this.debug('__deleteRecord(): id='+this.__currentId);
          this.__rpc.callAsyncSmart(qx.lang.Function.bind(this.__deleteRecordHandler, this),
                                    'deleteTableData', this.__tableId, this.__currentId);
        },

        __deleteRecordHandler : function(ret) {
            var sm  = this.__table.getSelectionModel();
            var tm  = this.__table.getTableModel();
            var row = sm.getSelectedRanges()[0].minIndex;
            this.debug('__deleteRecordHandler(): row='+row);
            tm.removeRow(row);
        },

        __dupRecord : function(e) {
            window.alert('Not yet implemented');
        },

        __editRecord : function(e) {
            this.__recordEdit.setRecord(this.__currentId);
            this.__recordEdit.open();
        },

        __newRecord : function(e) {
            this.__currentId = null;
            this.__recordEdit.setRecord(null);
            this.__recordEdit.open();
        },

        __filterTable : function(e) {
            var that = this;
            new dbtoria.window.TableFilter(this.tr("Filter: %1", this.__tableName),
                                           this.__columns,
                                           function(filter) {
//                                               this.debug('__filterTable(): calling setFilter()');
                                               that.__table.getTableModel().setFilter(filter);
                                               // qx.dev.Debug.debugObject(filter);
                                               // window.alert('Filter callback not yet implemented, filter='+filter);
                                           }
                                          );
        },

        __switchRecord : function(e) {
            var table  = this.__table;
            var model  = table.getTableModel();
            var selMod = table.getSelectionModel();
            var tbBtn  = this.__tbBtn;
            var row;

            var currentRow, currentSelection = selMod.getSelectedRanges()[0];
            if (currentSelection != null && currentSelection != undefined) {
                currentRow = currentSelection.minIndex;
            }

//            this.__lastId  = this.__currentId;
            this.__newRow = currentRow;

            selMod.iterateSelection(function(ind) {
                row = model.getRowData(ind);
            });
          this.debug('__switchRecord(): row='+row);
          qx.dev.Debug.debugObject(row);
            if (row) {
                this.__currentId = row.ROWINFO[0];
                this.__tbEdit.setEnabled(row.ROWINFO[1]);
                this.__tbDelete.setEnabled(row.ROWINFO[2]);
            }
            else {
                this.__tbEdit.setEnabled(false);
                this.__tbDelete.setEnabled(false);
                this.__currentId = null;
            }
            this.__recordEdit.setRecord(this.__currentId);
        }
    }
});
