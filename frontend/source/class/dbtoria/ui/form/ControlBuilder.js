/* ************************************************************************
   Copyright: 2009 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
   Utf8Check: äöü
************************************************************************ */

/* ************************************************************************
************************************************************************ */

qx.Class.define("dbtoria.ui.form.ControlBuilder", {
    type : 'static',

    statics : {
        /**
         * create a control and bind its value to the formData map
         *
         * @param desc {var} TODOC
         * @param formData {var} TODOC
         * @return {var} TODOC
         * @throws TODOC
         *
         * returns a control according to the description given
         *
         * <pre class='javascript'>
         * { type:    "TextArea",
         *   TODOC
         * },
         * { type:    "TextField",
         *   label:   "Label",
         *   filter:  "regexp",
         *   name:    "key",
         *   initial: "default value" },
         * { type:    "Date",
         *   label:   "Label",
         *   name:    "key",
         *   initial: "default value" },
         * { type:    "CheckBox",
         *   label:   "Label",
         *   name:    "key",
         *   initial: true },
         * { type:    "ComboTable",
         *   TODOC
         * },
         * </pre>
         *
         */

        createControl : function(desc, formDataCallback) {
            var control = null;
            var setter  = null;

            switch(desc.type) {
                case "ReadOnly":
                    control = new dbtoria.ui.form.TextField();
                    control.setEnabled(false);
                    if (qx.lang.Type.isNumber(desc.initial)) {
                        desc.initial = String(desc.initial);
                    }
                    break;

                case "TextField":
                    control = new dbtoria.ui.form.TextField();
                    if (qx.lang.Type.isNumber(desc.initial)) {
                        desc.initial = String(desc.initial);
                    }
                    break;

                case "TextArea":
                    control = new dbtoria.ui.form.TextArea();
                    if (qx.lang.Type.isNumber(desc.initial)) {
                        desc.initial = String(desc.initial);
                    }
                    break;

                case "Date":
                    control = new dbtoria.ui.form.DateField();

                    if (qx.lang.Type.isNumber(desc.initial)) {
                        // handle epoch seconds
                        desc.initial = new Date(desc.initial * 1000);
                    } else if (desc.initial) {
                        desc.initial = new Date(desc.initial);
                    }
                    break;

                case "CheckBox":
                    control = new dbtoria.ui.form.CheckBox();

                    if (qx.lang.Type.isNumber(desc.initial)) {
                        desc.initial = desc.initial == 1;
                    }
                    break;

                case "ComboTable":
                    var l = {};
                    l[desc.idCol] = 'id';
                    l[desc.valueCol] = 'value';
                    var remoteModel = new dbtoria.db.RemoteTableModel(desc.tableId,
                                                                      [desc.idCol,desc.valueCol], l);
                    control = new dbtoria.ui.form.ComboTable(remoteModel);
                    control.setModel(String(desc.initial));
                    control.setValue(String(desc.initialText));
                    delete desc.initial;
                    break;

                default:
                    throw new Error("Control '" + desc.type + "' is not yet supported");
                    break;
            }

            if (desc.hasOwnProperty('width')) {
                control.setWidth(desc.width);
            }
            if (desc.hasOwnProperty('initial')) {
                var initial = desc.initial;

                if (control.setModelSelection) {
                    if (!qx.lang.Type.isArray(initial)) {
                        initial = [ initial ];
                    }

                    control.setModelSelection(initial);
                }
                else {
                    control.setValue(initial);
                }
            }

            if (control.getModel) {
                control.addListener('changeModel',function(e){
                    formDataCallback(desc.name, e.getData());
                },this);
            }
            else if (control.getModelSelection) {
                control.addListener('changeSelection', function(e) {
                    var selected = control.getModelSelection();
                    var value;
                    if (desc.type == "SelectBox") {
                        value = selected.toArray()[0];
                    }
                    else {
                        value = selected.toArray();
                    }
                    formDataCallback(desc.name, e.getData());
                },this);
            }
            else {
                control.addListener('changeValue', function(e) {
                    formDataCallback(desc.name, e.getData());
                },this);
            }

            if (desc.required) {
                control.setRequired(true);
            }
            return control;
        },

        /**
         * TODOC
         *
         * @param control {var} TODOC
         * @param data {var} TODOC
         * @return {void}
         */
        _addListItems : function(control, data) {
            var vtr = this._vtr;

            for (var i=0; i<data.length; i++) {
                var item = data[i];

                if (qx.lang.Type.isObject(item)) {
                    var box = new qx.ui.form.ListItem(vtr(item.label));
                    box.setModel(item.model);
                    control.add(box);
                }
                else {
                    control.add(new qx.ui.form.ListItem(vtr(item)));
                }
            }
        },


        /**
         * TODOC
         *
         * @param control {var} TODOC
         * @param data {var} TODOC
         * @return {void}
         */
        _addCheckItems : function(control, data) {
            var vtr = this._vtr;

            for (var i=0; i<data.length; i++) {
                var item = data[i];

                if (qx.lang.Type.isObject(item)) {
                    var box = new qx.ui.form.CheckBox(vtr(item.label));
                    box.setModel(item.model);
                    control.add(box);
                }
                else {
                    control.add(new qx.ui.form.CheckBox(vtr(item)));
                }
            }
        },


        /**
         * TODOC
         *
         * @param x {var} TODOC
         * @return {var} TODOC
         */
        _vtr : function(x) {
            var trans = qx.locale.Manager;
            return x.translate ? x : trans['tr'](x);
        }
    }
});
