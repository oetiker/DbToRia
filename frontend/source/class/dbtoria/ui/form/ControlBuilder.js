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
                    control = new qx.ui.form.TextField();
                    control.setEnabled(false);
                    if (qx.lang.Type.isNumber(desc.initial)) {
                        desc.initial = String(desc.initial);
                    }
                    setter = function(value) {
                        if (value == null) {
                            control.setValue(value);
                        }
                        else {
                            control.setValue(String(value));
                        }
                    };

                    break;

                case "TextField":
                    control = new qx.ui.form.TextField();
                    if (qx.lang.Type.isNumber(desc.initial)) {
                        desc.initial = String(desc.initial);
                    }
                    setter = function(value) {
                        if (value == null) {
                            control.setValue(value);
                        }
                        else {
                            control.setValue(String(value));
                        }
                    };

                    break;

                case "TextArea":
                    control = new qx.ui.form.TextArea();
                    setter = function(value) {
                        if (value == null) {
                            control.setValue(value);
                        }
                        else {
                            control.setValue(String(value));
                        }
                    };

                    break;

                case "Date":
                    control = new qx.ui.form.DateField();

                    if (qx.lang.Type.isNumber(desc.initial)) {
                        // handle epoch seconds
                        desc.initial = new Date(desc.initial * 1000);
                    } else if (desc.initial) {
                        desc.initial = new Date(desc.initial);
                    }

                    control.set({ allowGrowX : false });
                    setter = function(value) {
//                        qx.log.Logger.debug('Calling setValue(new Date(value)) for type='+desc.type);
                        if (value == null) {
                            control.setValue(null);
                        }
                        else {
                            control.setValue(new Date(value));
                        }
                    };
                    break;

                case "CheckBox":
                    control = new qx.ui.form.CheckBox();

                    if (qx.lang.Type.isNumber(desc.initial)) {
                        desc.initial = desc.initial == 1;
                    }

                    setter = function(value) {
                        if (value == null) {
                            control.setValue(false);
                        }
                        else {
                            control.setValue(value);
                        }
                    };

                    break;

                case "ComboTable":
                    var l = {};
                    l[desc.idCol] = 'id';
                    l[desc.valueCol] = 'value';
                    var remoteModel = new dbtoria.db.RemoteTableModel(desc.tableId,
                                                                      [desc.idCol,desc.valueCol], l);
                    control = new combotable.ComboTable(remoteModel);
                    control.setModel(String(desc.initial));
                    control.setValue(String(desc.initialText));
                    delete desc.initial;

                    setter = function(value) {
//                        qx.log.Logger.debug('Calling setModel/setValue() for type='+desc.type);
                        if (value == null || value.id == undefined || value.id == null) {
                            control.setModel(0);
                            control.setValue('undefined');
                        }
                        else {
                            control.setModel(value.id);
                            control.setValue(value.text);
                        }
                    };

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

            return { control: control, setter: setter };
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
