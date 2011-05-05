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

        this._rpc = dbtoria.data.Rpc.getInstance();
        this.moveTo(300, 40);

        var actionRow = new qx.ui.container.Composite(new qx.ui.layout.HBox(5));

        this._createNavigation(actionRow);
        this._createActions(actionRow);

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
        _form            : null,
        __formModel       : null,
        __scrollContainer : null,
        __tableId         : null,
        __tableName       : null,
        _recordId        : null,
        _rpc             : null,
        __readOnly        : null,

        _initForm: function() {
            this._rpc.callAsyncSmart(qx.lang.Function.bind(this._fillForm, this), 'getEditView', this.__tableId);
        },

        __createButton: function(icon, tooltip, target) {
            var btn = new dbtoria.ui.form.Button(null, icon, tooltip);
            btn.addListener('execute', function() {
                this.fireDataEvent('navigation', target);
            }, this);
            btn.setMinWidth(null);
            return btn;
        },

        _createNavigation: function(readOnly) {
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
            if (recordId == this._recordId) { // nothing changed
                return;
            }
        },

        editRecord : function(recordId) {
            this.debug("editRecord(): recordId="+recordId);
            this.__setFormData(recordId, 'edit');
            if (!this.isVisible()) {
                this.open();
            }
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
                        that._recordId = null;
                    }
                    else {
                        that._recordId = recordId;
                    }
                    that._form.setFormData(data);
                    that._form.setFormDataChanged(false);
                }
                that.setLoading(false);
            };
            this._rpc.callAsync(setFormDataHandler, 'getRecordDeref', this.__tableId, recordId);
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
            this._form = form;
        }
    }
});
