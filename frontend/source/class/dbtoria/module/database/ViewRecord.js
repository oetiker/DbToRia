/* ************************************************************************

   Copyrigtht: OETIKER+PARTNER AG
   License:    GPL
   Authors:    Tobias Oetiker
               Fritz Zaucker

   Utf8Check:  äöü

   $Id: AdminEditor.js 333 2010-10-05 20:07:53Z oetiker $

************************************************************************ */

/* ************************************************************************
#asset(qx/icon/${qx.icontheme}/16/apps/utilities-text-editor.png)
#asset(qx/icon/${qx.icontheme}/16/actions/dialog-cancel.png)
************************************************************************ */

// FIX ME:
//   - documentation

/**
 * Popup window for editing a database record.
 */
qx.Class.define("dbtoria.module.database.ViewRecord", {
    extend : dbtoria.module.database.AbstractRecord,

    construct : function(tableId, tableName) {
        this.base(arguments);

        this.set({
            icon                 : 'icon/16/apps/utilities-text-editor.png',
            caption              : this.tr('Edit record: %1', tableName)
        });

    },

    events: {
        "saveRecord" : "qx.event.type.Data",
        "navigation"  : "qx.event.type.Data",
        "refresh"     : "qx.event.type.Data"
    }, // events

    members : {

        cancel: function() {
//            this._form.setFormDataChanged(false); // abort, don't save afterwards
            this.close();
        },

        _createActions: function() {
            var btnCnl = new dbtoria.ui.form.Button(this.tr("Cancel"), "icon/16/actions/dialog-cancel.png",
                                                    this.tr('Abort editing without saving'));
            btnCnl.addListener("execute", this.cancel, this);

            var btnRow = new qx.ui.container.Composite(new qx.ui.layout.HBox(5));
            btnRow.add(btnCnl);
            return btnRow;
        },

        /* TODOC
         *
         * @param record {var} TODOC
         * @return {void}
         */
        viewRecord : function(recordId) {
            this.debug("viewRecord(): recordId="+recordId);
            this.__setFormData(recordId, 'edit');
            this.setCaption("View record: "+this.__tableName);
            if (!this.isVisible()) {
                this.open();
            }
        }

    }
});
