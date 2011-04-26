/* ************************************************************************

   Copyrigtht: OETIKER+PARTNER AG
   License:    GPL
   Authors:    Tobias Oetiker
   Utf8Check:  äöü

   $Id: AdminEditor.js 333 2010-10-05 20:07:53Z oetiker $

************************************************************************ */

/* ************************************************************************
#asset(qx/icon/${qx.icontheme}/16/apps/utilities-text-editor.png)
#asset(qx/icon/${qx.icontheme}/16/actions/dialog-apply.png)
#asset(qx/icon/${qx.icontheme}/16/actions/dialog-cancel.png)
************************************************************************ */

// FIX ME:
//   - documentation
//   - SVN ID

/**
 * Popup window for editing a database record.
 */
qx.Class.define("dbtoria.window.RecordEdit", {
    extend : dbtoria.window.DesktopWindow,

    construct : function(tableId, recordId, title) {
        this.base(arguments);

        this.set({
            caption              : title,
            icon                 : 'icon/16/apps/utilities-text-editor.png',
            showMinimize         : true,
            contentPaddingLeft   : 20,
            contentPaddingRight  : 20,
            contentPaddingTop    : 20,
            contentPaddingBottom : 10,
            layout               : new qx.ui.layout.VBox(10),
            width                : 400,
            height               : 300
        });

        var scrollContainer = new qx.ui.container.Scroll();
        this.__scrollContainer = scrollContainer;
        this.add(scrollContainer, { flex: 1 });

        var rpc = dbtoria.communication.Rpc.getInstance();
        rpc.callAsyncSmart(qx.lang.Function.bind(this._fillForm, this), 'getForm', tableId, recordId);
        this.moveTo(300, 40);
        this.open();

        var btnRow = new qx.ui.container.Composite(new qx.ui.layout.HBox(5,'right'));
        this.add(btnRow);

        var btnCnl = new qx.ui.form.Button(this.tr("Cancel"), "icon/16/actions/dialog-cancel.png").set({
            allowGrowX : false,
            allowGrowY : false
        });
        
        btnCnl.addListener("execute", function(e) {
            this.close();
            this.destroy();
        },
        this);
    
        btnRow.add(btnCnl);

        var btnApp = new qx.ui.form.Button(this.tr("Apply"), "icon/16/actions/dialog-apply.png").set({
            allowGrowX : false,
            allowGrowY : false
        });

        btnApp.addListener("execute", function(e) {
            if (this.__form.validate()){
                var that = this;

                rpc.callAsyncSmart(function(id) {
                    that.close();
                    that.destroy();
                },
                'insertTableData', tableId,  this.__formModel);
            }

            else {
                var msg = dbtoria.dialog.MsgBox.getInstance();
                msg.error(this.tr("Form Invalid"), this.tr('Make sure all your form input is valid. The invalid entries have been marked in red. Move the mouse over the marked entry to get more information about the problem.'));
            }
        },
        this);
        btnRow.add(btnApp);
    },

    members : {
        __formModel       : null,
        __form            : null,
        __scrollContainer : null,

        /**
         * TODOC
         *
         * @param rules {var} TODOC
         * @return {void}
         */
        _fillForm : function(rules) {
            var form = new dbtoria.ui.form.AutoForm(rules);
            this.__formModel = form.getModel();
            var formControl = new dbtoria.ui.form.renderer.Monster(form);

            this.__scrollContainer.add(formControl);
            this.__form = form;
        }
    }
});
