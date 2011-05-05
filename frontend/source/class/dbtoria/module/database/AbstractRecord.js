/* ************************************************************************

   Copyrigtht: OETIKER+PARTNER AG
   License:    GPL
   Authors:    Tobias Oetiker
               Fritz Zaucker

   Utf8Check:  äöü

   $Id: AdminEditor.js 333 2010-10-05 20:07:53Z oetiker $

************************************************************************ */

/* ************************************************************************
#asset(qx/icon/${qx.icontheme}/16/actions/go-first.png)
#asset(qx/icon/${qx.icontheme}/16/actions/go-previous.png)
#asset(qx/icon/${qx.icontheme}/16/actions/go-next.png)
#asset(qx/icon/${qx.icontheme}/16/actions/go-last.png)
************************************************************************ */

// FIX ME:
//   - documentation

/**
 * Popup window for editing a database record.
 */
qx.Class.define("dbtoria.module.database.AbstractRecord", {
    extend : dbtoria.module.desktop.Window,
    type   : "abstract",

    construct : function(tableId, tableName) {
        this.base(arguments);
        this.__tableId   = tableId;
        this.__tableName = tableName;

        var maxHeight = qx.bom.Document.getHeight() - 100;
        this.addListener("appear",  function(e) {
            var maxHeight = qx.bom.Document.getHeight() - 100;
            this.setHeight(maxHeight);
        }, this);

        this.set({
            showMinimize         : true,
            showClose            : true,
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

        this.__rpc = dbtoria.data.Rpc.getInstance();
        this.__rpc.callAsyncSmart(qx.lang.Function.bind(this._fillForm, this), 'getEditView', tableId);
        this.moveTo(300, 40);

        this.add(this.__createNavigation());

        this.addListener('keyup', function(e) {
            if (e.getKeyIdentifier() == 'Escape') {
                this.cancel();
            }
        },this);

    },

    events: {
//        "saveRecord" : "qx.event.type.Data",
//        "refresh"     : "qx.event.type.Data"
        "navigation"  : "qx.event.type.Data"
    }, // events

    members : {
        __formModel       : null,
        __form            : null,
        __scrollContainer : null,
        __tableId         : null,
        __tableName       : null,
        __recordId        : null,
        __rpc             : null,
        __readOnly        : null,

        __createButton: function(icon, tooltip, target) {
            var btn = new dbtoria.ui.form.Button(null, icon, tooltip);
            btn.addListener('execute', function() {
                this.fireDataEvent('navigation', target);
            }, this);
            btn.setMinWidth(null);
            return btn;
        },

        __createNavigation: function(readOnly) {
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

            var btnRow = new qx.ui.container.Composite(new qx.ui.layout.HBox(5));
            btnRow.add(btnFirst);
            btnRow.add(btnBack);
            btnRow.add(btnNext);
            btnRow.add(btnLast);
            if (!readOnly) {
                btnRow.add(btnNew);
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
        },

        editRecord : function(recordId) {
            this.debug("editRecord(): recordId="+recordId);
            this.__setFormData(recordId, 'edit');
            if (this.__readOnly) {
                this.setCaption("View record: "+this.__tableName);
            }
            else {
                this.setCaption("Edit record: "+this.__tableName);
            }
            if (!this.isVisible()) {
                this.open();
            }
        },

        cloneRecord : function(recordId) {
            this.debug("cloneRecord(): recordId="+recordId);
            this.__setFormData(recordId, 'clone');
            this.setCaption("Clone record: "+this.__tableName);
            if (!this.isVisible()) {
                this.open();
            }
        },

        newRecord : function() {
            this.debug('newRecord() called');
            this.__setDefaults();
//            this.__setFormData(null, 'new');
            this.setCaption("New record: "+this.__tableName);
            if (!this.isVisible()) {
                this.open();
            }
        },

        saveRecord : function() {
            if (!this.__form.getFormDataChanged()) {
                this.debug("Form data didn't change, not saving.");
                this.fireDataEvent('saveRecord', null);
                return;
            }

            this.debug('saveRecord(): id='+this.__recordId);
            if (!this.__form.validate()) {
                this.debug('Form validation failed');
                this.fireDataEvent('saveRecord', 'invalid');
                var msg = dbtoria.ui.dialog.MsgBox.getInstance();
                msg.error(this.tr('Form invalid'), this.tr('Make sure all your form input is valid. The invalid entries have been marked in red. Move the mouse over the marked entry to get more information about the problem.'));
                return;
            }

            this.debug('Form validation ok');
            var data = this.__form.getFormData();
            // qx.dev.Debug.debugObject(data);
            this.setLoading(true);
            if (this.__recordId == null) {
                this.__rpc.callAsync(qx.lang.Function.bind(this.__saveRecordHandler, this),
                                     'insertTableData', this.__tableId, data);
            }
            else {
                this.__rpc.callAsync(qx.lang.Function.bind(this.__saveRecordHandler, this),
                                     'updateTableData', this.__tableId, this.__recordId, data);
            }
        },


        __saveRecordHandler : function(data, exc, id) {
            if (exc) {
                dbtoria.ui.dialog.MsgBox.getInstance().exc(exc);
                this.debug('__saveRecordHandler() failed');
                this.fireDataEvent('saveRecord', 'failed');
            }
            else {
                if (this.__recordId == null) {
                    this.__recordId = data;
                }
                this.debug('__saveRecordHandler() successful, record='+this.__recordId);
                this.fireDataEvent('saveRecord', 'succeeded');
            }
            this.setLoading(false);
        },

        /**
         * TODOC
         *
         * @return {void}
         */
         __setDefaults : function() {
             this.debug('Called __setDefaults()');
             // only clear fields that don't have copyForward attribute
             this.__recordId = null;
             this.__form.clearPartial();
             this.setLoading(true);
             this.__rpc.callAsync(qx.lang.Function.bind(this.__getDefaultsHandler, this),
                                  'getDefaultsDeref', this.__tableId);
         },

        /**
         * TODOC
         *
         * @param rules {var} TODOC
         * @return {void}
         */
      __getDefaultsHandler : function(data, exc, id) {
            if (exc) {
                dbtoria.ui.dialog.MsgBox.getInstance().exc(exc);
            }
            else {
                this.debug('__getDefaultsHandler(): data=');
//            qx.dev.Debug.debugObject(data);
                this.__form.setDefaults(data);
                this.__form.setFormDataChanged(true);
            }
            this.setLoading(false);
        },

        /**
         * TODOC
         *
         * @return {void}
         */
        __setFormData : function(recordId, action) {
            this.debug('Called __setFormData(): record='+recordId+', action='+action);
            this.setLoading(true);
            var that = this;
            var setFormDataHandler = function(data, exc, id) {
                if (exc) {
                    dbtoria.ui.dialog.MsgBox.getInstance().exc(exc);
                }
                else {
                    if (action == 'clone'){
                        that.__recordId = null;
                    }
                    else {
                        that.__recordId = recordId;
                    }
                    that.__form.setFormData(data);
                    that.__form.setFormDataChanged(false);
                }
                that.setLoading(false);
            };
            this.__rpc.callAsync(setFormDataHandler, 'getRecordDeref', this.__tableId, recordId);
         },

        /**
         * TODOC
         *
         * @param rules {var} TODOC
         * @return {void}
         */
        _fillForm : function(rules) {
            var form         = new dbtoria.ui.form.AutoForm(rules);
            if (this.__readOnly) {
                // only for readOnly forms, otherwise readOnly fields would get enabled
                form.setReadOnly(this.__readOnly);
            }
            this.__formModel = form.getFormData();
            var formControl  = new dbtoria.ui.form.renderer.Monster(form);
            this.__scrollContainer.add(formControl, {flex:1});
            this.__form = form;
        }
    }
});
