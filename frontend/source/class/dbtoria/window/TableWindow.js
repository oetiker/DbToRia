/* ************************************************************************

  DbToRia - Database to Rich Internet Application

  http://www.dbtoria.org

   Copyright:
    2009 David Angleitner, Switzerland

   License:
    GPL: http://www.gnu.org/licenses/gpl-2.0.html

   Authors:
    * David Angleitner

************************************************************************ */

/* ************************************************************************

#asset(dbtoria/*)
#asset(qx/icon/${qx.icontheme}/16/mimetypes/text-plain.png)
#asset(qx/icon/${qx.icontheme}/16/actions/contact-new.png)
#asset(qx/icon/${qx.icontheme}/16/actions/edit-delete.png)
#asset(qx/icon/${qx.icontheme}/16/actions/view-refresh.png)
#asset(qx/icon/${qx.icontheme}/16/actions/document-save-as.png)
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
    extend : qx.ui.window.Window,
    construct : function(tableId, tableName) {
        this.__tableName = tableName;
        this.__tableId   = tableId;
        this.base(arguments, this.tr('Table: %1', tableName));
        this.set({
            contentPadding : 0,
            width          : 800,
            height         : 500,
            layout         : new qx.ui.layout.VBox().set({ separator: "separator-vertical"})
        });

        // on clicking the minimize button a new button on the taskbar is
        // generated which allows to restore the window again
        this.addListener("minimize", function(e) {
            var taskbarButton = new qx.ui.toolbar.Button(tableName, "icon/16/mimetypes/text-plain.png");
            var tb = dbtoria.window.Taskbar.getInstance();
            tb.add(taskbarButton);
            taskbarButton.addListener("execute", function(e) {
                this.open();
                tb.remove(taskbarButton);
            },
            this);
        },
        this);
//      this.addListenerOnce("close", function(e) {
//           this.close();
//      });
        this.__buildUi(tableId);
        this.open();
    },

    members : {
        __table:     null,
        __tbEdit:    null,
        __tbDelete:  null,
        __currentId: null,
        __tableName: null,
        __tableId:   null,
        /**
         * Display a table overview with data
         *
         * @return {void}
         */
        __buildUi : function(tableId) {
            var toolbar = new qx.ui.toolbar.ToolBar();
            var newButton = new qx.ui.toolbar.Button(this.tr("New"), "icon/16/actions/contact-new.png");
            var editButton = this.__tbEdit = new qx.ui.toolbar.Button(this.tr("Edit"), "icon/16/apps/utilities-text-editor.png").set({enabled: false});
            var dupButton = new qx.ui.toolbar.Button(this.tr("Copy"), "icon/16/actions/edit-copy.png").set({enabled: false});
            var deleteButton = this.__tbDelete = new qx.ui.toolbar.Button(this.tr("Delete"), "icon/16/actions/edit-delete.png").set({enabled: false});
            var refreshButton = new qx.ui.toolbar.Button(this.tr("Refresh"), "icon/16/actions/view-refresh.png").set({enabled: false});
            var exportButton = new qx.ui.toolbar.Button(this.tr("Export"), "icon/16/actions/document-save-as.png").set({enabled: false});
            var filterButton = new qx.ui.toolbar.CheckBox(this.tr("Search"), "icon/16/actions/system-search.png").set({enabled: false});

            toolbar.add(newButton);
            newButton.addListener('execute',function(e){
                new dbtoria.window.RecordEdit(tableId,null,"New "+this.__tableName);
            },this);

            toolbar.add(editButton);
            editButton.addListener('execute', this.__editRecord, this);

            toolbar.add(dupButton);
            toolbar.add(deleteButton);
            toolbar.addSpacer();
            toolbar.add(refreshButton);
            toolbar.add(exportButton);
            toolbar.add(filterButton);

            this.add(toolbar);
            var rpc = dbtoria.communication.Rpc.getInstance();
            var that = this;
            rpc.callAsyncSmart(function(ret){
                var columns = ret.columns;
                var tableId = ret.tableId;
                var columnIds = [];
                var columnLabels = {};
                for (var i=0;i<columns.length;i++){
                    columnIds.push(columns[i].id);
                    columnLabels[columns[i].id] = columns[i].name;
                }
                var model = new dbtoria.db.RemoteTableModel(tableId,columnIds,columnLabels);
                that.__table = new dbtoria.window.Table(model);
                that.__table.getSelectionModel().addListener('changeSelection',that.__switchRecord, that);
                that.__table.addListener("cellDblclick", that.__editRecord, that);
                that.add(that.__table, { flex : 1 });
            },'getListView',tableId);
        },

        __editRecord : function(e) {
            new dbtoria.window.RecordEdit(this.__tableId, this.__currentId, "Edit "+this.__tableName);
        },

        __switchRecord : function(e) {
            var table = this.__table;
            var model = table.getTableModel();
            var selMod = table.getSelectionModel();
            var tbBtn = this.__tbBtn;
            var row;

            selMod.iterateSelection(function(ind) {
                row = model.getRowData(ind);
            });

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
        }
    }
});
