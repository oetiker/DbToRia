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
#asset(qx/icon/${qx.icontheme}/16/mimetypes/office-calendar.png)
#asset(qx/icon/${qx.icontheme}/22/actions/document-new.png)
#asset(qx/icon/${qx.icontheme}/22/actions/dialog-cancel.png)
#asset(qx/icon/${qx.icontheme}/22/actions/edit-redo.png)
#asset(qx/icon/${qx.icontheme}/22/actions/document-print.png)
#asset(qx/icon/${qx.icontheme}/22/actions/edit-find.png)

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
        this.base(arguments, this.tr('Table: %1', tableName));
        this.set({
            contentPadding : 0,
            margin         : 0,
            width          : 800,
            height         : 500,
            layout         : new qx.ui.layout.VBox()
        });

        // on clicking the minimize button a new button on the taskbar is
        // generated which allows to restore the window again
        this.addListener("minimize", function(e) {
            var taskbarButton = new qx.ui.toolbar.Button(tableName, "icon/16/mimetypes/office-calendar.png");
            var tb = dbtoria.window.Taskbar.getInstance();
            tb.add(taskbarButton);
            taskbarButton.addListener("execute", function(e) {
                this.open();
                tb.remove(taskbarButton);
            },
            this);
        },
        this);
//        this.addListenerOnce("close", function(e) {
//            this.close();
//        });
        this.center();
        this.open();
        this.__buildUi(tableId);
    },

    members : {
        __table: null,
        /**
         * Display a table overview with data
         *
         * @return {void} 
         */
        __buildUi : function(tableId) {
            var toolbar = new qx.ui.toolbar.ToolBar();
            var newButton = new qx.ui.toolbar.Button(this.tr("New Entry"), "icon/22/actions/document-new.png");
            var deleteButton = new qx.ui.toolbar.Button(this.tr("Delete Selection"), "icon/22/actions/dialog-cancel.png");
            var refreshButton = new qx.ui.toolbar.Button(this.tr("Refresh"), "icon/22/actions/edit-redo.png");
            var exportButton = new qx.ui.toolbar.Button(this.tr("Export"), "icon/22/actions/document-print.png");
            var filterButton = new qx.ui.toolbar.CheckBox(this.tr("Search"), "icon/22/actions/edit-find.png");
            toolbar.add(newButton);
            toolbar.add(deleteButton);
            toolbar.add(refreshButton);
            toolbar.addSpacer();
            toolbar.add(exportButton);
            toolbar.add(filterButton);
            this.add(toolbar);
            var rpc = dbtoria.communication.Rpc.getInstance();
            var that = this;
            rpc.callAsyncSmart(function(ret){
                var columnIds = [];
                var columnLabels = {};
                for (var i=0;i<ret.length;i++){
                    columnIds.push(ret[i].id);
                    columnLabels[ret[i].id] = ret[i].name;
                }
                var model = new dbtoria.db.RemoteTableModel(tableId,columnIds,columnLabels);
                that.__table = new dbtoria.window.Table(model);
                that.add(that.__table, { flex : 1 });
            },'getTableStructure',tableId);
        }
    }
});
