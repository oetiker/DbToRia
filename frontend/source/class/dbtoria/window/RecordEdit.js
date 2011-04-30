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
#asset(qx/icon/${qx.icontheme}/16/actions/go-first.png)
#asset(qx/icon/${qx.icontheme}/16/actions/go-previous.png)
#asset(qx/icon/${qx.icontheme}/16/actions/go-next.png)
#asset(qx/icon/${qx.icontheme}/16/actions/go-last.png)
#asset(qx/icon/${qx.icontheme}/16/actions/help-about.png)
************************************************************************ */

// FIX ME:
//   - documentation
//   - SVN ID

/**
 * Popup window for editing a database record.
 */
qx.Class.define("dbtoria.window.RecordEdit", {
    extend : dbtoria.window.DesktopWindow,

    construct : function(tableId, tableName, viewMode) {
        this.base(arguments);
        this.__tableId   = tableId;
        this.__tableName = tableName;

        var maxHeight = qx.bom.Document.getHeight() - 100;
//        var maxWidth =  qx.bom.Document.getWidth() - 20;
        this.addListener("appear",  function(e) {
            var maxHeight = qx.bom.Document.getHeight() - 100;
            this.setHeight(maxHeight);
        }, this);

        this.set({
            icon                 : 'icon/16/apps/utilities-text-editor.png',
            showMinimize         : true,
            showClose            : false,
            contentPaddingLeft   : 20,
            contentPaddingRight  : 20,
            contentPaddingTop    : 20,
            contentPaddingBottom : 10,
            layout               : new qx.ui.layout.VBox(10),
            minWidth             : 400,
//             maxHeight           : maxHeight,
            height           : maxHeight,
            allowGrowX : true,
            allowGrowY : true
        });

        var scrollContainer = new qx.ui.container.Scroll();
        scrollContainer.set({
            allowGrowX: true,
            allowGrowY: true
        });
        this.__scrollContainer = scrollContainer;
        this.add(scrollContainer, { flex: 1 });

        this.__rpc = dbtoria.io.remote.Rpc.getInstance();
        this.__rpc.callAsyncSmart(qx.lang.Function.bind(this._fillForm, this), 'getEditView', tableId);
        this.moveTo(300, 40);


        this.add(this.__createNavigation(viewMode));

        this.addListener("appear", function(e) {
            var recordId = this.__recordId;
            if (recordId == null) {
                this.__setDefaults();
            }
            else {
                this.__setFormData();
            }

        }, this);

        this.addListener("close", function(e) {
            this.__saveRecord('close');
        }, this);

        this.addListener('keyup', function(e) {
            if (e.getKeyIdentifier() == 'Enter') {
                this.close();
            }
            if (e.getKeyIdentifier() == 'Escape') {
                this.cancel();
            }
        });

    },

    events: {
        "navigation" : "qx.event.type.Data",
        "refresh"    : "qx.event.type.Event",
        "done"       : "qx.event.type.Event",
        "undo"       : "qx.event.type.Event"
    }, // events

    members : {
        __formModel       : null,
        __form            : null,
        __scrollContainer : null,
        __tableId         : null,
        __tableName       : null,
        __recordId        : null,
        __rpc             : null,
        __target          : null,
        __postAction      : null,

          close: function() {
              this.base(arguments);
          },

          __createButton: function(icon, tooltip, target) {
            var btn = new dbtoria.ui.form.Button(null, icon, tooltip);
            btn.addListener('execute', function() {
                this.__target = target;
                this.fireDataEvent('navigation', target);
            }, this);
            btn.setMinWidth(null);
            return btn;
        },

        cancel: function() {
            this.__form.setFormDataChanged(false); // abort, don't save afterwards
            this.close();
        },

        __createNavigation: function(viewMode) {
            var btnFirst = this.__createButton("icon/16/actions/go-first.png",
                                               this.tr("Jump to first record"),  'first');
            var btnBack  = this.__createButton("icon/16/actions/go-previous.png",
                                               this.tr("Go to previous record"), 'back');
            var btnNext  = this.__createButton("icon/16/actions/go-next.png",
                                               this.tr("Go to next record"),     'next');
            var btnLast  = this.__createButton("icon/16/actions/go-last.png",
                                               this.tr("Jump to last record"),   'last');
            var btnNew   = this.__createButton("icon/16/actions/help-about.png",
                                               this.tr("Open new record"),       'new');

            var btnCnl = new dbtoria.ui.form.Button(this.tr("Cancel"), "icon/16/actions/dialog-cancel.png",
                                                    this.tr('Abort editing without saving'));
            btnCnl.addListener("execute", function(e) {
                this.cancel();
            }, this);

            var btnApp = new dbtoria.ui.form.Button(this.tr("Apply"), "icon/16/actions/dialog-apply.png",
                                                    this.tr('Save form content to backend'));
            btnApp.addListener("execute", function(e) {
                this.__saveRecord('apply');
            }, this);

            var btnOk  = new dbtoria.ui.form.Button(this.tr("OK"), "icon/16/actions/dialog-ok.png",
                                                    this.tr('Save form content to backend and close window'));
            btnOk.addListener("execute", function(e) {
                this.__saveRecord('close');
            }, this);

            var btnRow = new qx.ui.container.Composite(new qx.ui.layout.HBox(5));
            btnRow.add(btnFirst);
            btnRow.add(btnBack);
            btnRow.add(btnNext);
            btnRow.add(btnLast);
            if (!viewMode) {
                btnRow.add(btnNew);
            }
            btnRow.add(new qx.ui.core.Spacer(1,1), {flex:1});
            btnRow.add(btnOk);
            if (!viewMode) {
                btnRow.add(btnCnl);
                btnRow.add(btnApp);
            }
            return btnRow;
        },

        /* TODOC
         *
         * @param record {var} TODOC
         * @return {void}
         */
        setRecord : function(recordId) {
            this.debug("setRecord(): recordId="+recordId);
            if (recordId == this.__recordId) { // nothing changed
                return;
            }
            this.__saveRecord(recordId);
        },

        __saveRecord : function(recordId) {
            if (recordId != 'close' && recordId != 'apply') {
                this.__newRecord = recordId;
            }
            if (!this.__form.getFormDataChanged()) {
                this.debug("Form data didn't change, not saving.");
                this.__setNewRecord();
                this.fireEvent('done');
                return;
            }
            this.debug('__saveRecord(): id='+this.__recordId);
            if (this.__form.validate()) {
                this.debug('Form validation ok');
                var data = this.__form.getFormData();
                qx.dev.Debug.debugObject(data);
                this.setLoading(true);
                if (this.__recordId == null) {
                    this.__rpc.callAsync(qx.lang.Function.bind(this.__saveRecordHandler, this),
                                         'insertTableData', this.__tableId, data);
                }
                else {
                    this.__rpc.callAsync(qx.lang.Function.bind(this.__saveRecordHandler, this),
                                         'updateTableData', this.__tableId, this.__recordId, data);
               }
            }
            else {
                this.debug('Form validation failed');
                this.fireEvent('undo');
                var msg = dbtoria.dialog.MsgBox.getInstance();
                msg.error(this.tr("Form Invalid"), this.tr('Make sure all your form input is valid. The invalid entries have been marked in red. Move the mouse over the marked entry to get more information about the problem.'));
            }
        },

        __saveRecordHandler : function(data, exc, id) {
            if (exc) {
                dbtoria.dialog.MsgBox.getInstance().exc(exc);
                this.debug('__saveRecordHandler() failed');
                this.fireEvent('undo');
            }
            else {
                this.debug('__saveRecordHandler() successful');
                this.fireEvent('refresh');
                this.__setNewRecord();
            }
            this.setLoading(false);
        },

        __setNewRecord: function() {
            this.setLoading(true);
            var recordId = this.__newRecord;
//             this.debug('__setNewRecord(): record='+recordId);
            this.__recordId = recordId;
            if (recordId == null) {
                this.__setDefaults();
                return;
            }
            if (this.isVisible()) {
                this.__setFormData();
            }
        },

        /**
         * TODOC
         *
         * @return {void}
         */
         __setDefaults : function() {
//             this.debug('Called __setDefaults()');
             this.__form.clear();
             this.setCaption("New "+this.__tableName);
             this.setLoading(true);
             // FIX ME: copy from previous record functionality
             this.__rpc.callAsyncSmart(qx.lang.Function.bind(this.__getDefaultsHandler, this), 'getDefaultsDeref',
                                       this.__tableId);
         },

        /**
         * TODOC
         *
         * @param rules {var} TODOC
         * @return {void}
         */
        __getDefaultsHandler : function(data) {
            this.__form.setFormData(data);
            this.__form.setFormDataChanged(true);
            this.setLoading(false);
        },

        /**
         * TODOC
         *
         * @return {void}
         */
         __setFormData : function(recordId) {
//             this.debug('Called __setFormData()');
             this.setCaption("Edit "+this.__tableName);
             this.__rpc.callAsyncSmart(qx.lang.Function.bind(this.__setFormDataHandler, this), 'getRecordDeref',
                                       this.__tableId, this.__recordId);
         },

        /**
         * TODOC
         *
         * @param rules {var} TODOC
         * @return {void}
         */
        __setFormDataHandler : function(data) {
            this.__form.setFormData(data);
            this.__form.setFormDataChanged(false);
            this.setLoading(false);
        },

        /**
         * TODOC
         *
         * @param rules {var} TODOC
         * @return {void}
         */
        _fillForm : function(rules) {
            var form         = new dbtoria.ui.form.AutoForm(rules);
            this.__formModel = form.getFormData();
            var formControl  = new dbtoria.ui.form.renderer.Monster(form);
            this.__scrollContainer.add(formControl, {flex:1});
            this.__form = form;
        }
    }
});
