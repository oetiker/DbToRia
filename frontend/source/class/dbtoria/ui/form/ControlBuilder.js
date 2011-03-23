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
         * create a control and bind its value to the model map
         *
         * @param desc {var} TODOC
         * @param model {var} TODOC
         * @return {var} TODOC
         * @throws TODOC
         *
         * returns a control according to the description given
         *
         * <pre class='javascript'>
         * { type:    "TextLabel",
         *   label:   "Info",
         *   name:    "key",
         *   initial: "default value" },
         * { type:    "TextField",
         *   label:   "Label",
         *   filter:  "regexp",
         *   name:    "key",
         *   initial: "default value" },
         * { type:    "PasswordField",
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
         * { type:    "Spinner",
         *   label:   "Label",
         *   name:    "key",
         *   initial: 23,
         *   min:     1,
         *   max:     40 },
         * { type:    "SelectBox",
         *   label:   "Label",
         *   name:    "key",
         *   initial: "Peter",
         *   data:    ['Peter', 'Karl', 'Max']
         * or data:   [{label: 'Peter', model: 11}, ...]
         * },
         * { type:    "MultiPick",
         *   label:   "Label",
         *   name:    "key",
         *   initial: [11,23],
         *   data:    ['Peter', 'Karl', 'Max']
         * or data:   [{label: 'Peter', model: 11}, ...]
         * { type:    "OpAndValue",
         *   label:   "Label",
         *   name:    "key",
         *   initial: ['>',null],
         *   data:    ['>','=','<','!=','<=','>=']
         * }
         * { type:    "OpAndDate",
         *   label:   "Label",
         *   name:    "key",
         *   initial: ['>',null],
         *   data:    ['>','=','<','!=','<=','>=']
         * }
         * </pre>
         *
         *
         */
        createControl : function(desc, model) {
            var control = null;

            if (qx.lang.Type.isObject(model)) {
                if (model.hasOwnProperty(desc.name)) {
                    desc.initial = model[desc.name];
                } else {
                    model[desc.name] = desc.initial;
                }
            }

            switch(desc.type)
            {
                case "TextField":
                    control = new qx.ui.form.TextField();

                    if (qx.lang.Type.isNumber(desc.initial)) {
                        desc.initial = String(desc.initial);
                    }

                    break;

                case "PasswordField":
                    control = new qx.ui.form.PasswordField();

                    if (qx.lang.Type.isNumber(desc.initial)) {
                        desc.initial = String(desc.initial);
                    }

                    break;

                case "TextLabel":
                    control = new qx.ui.form.TextField().set({
                        readOnly  : true,
                        decorator : null
                    });

                    break;

                case "Date":
                    control = new qx.ui.form.DateField();
                    control.set({ placeholder : this._vtr('dd.mm.jjjj') });

                    if (qx.lang.Type.isNumber(desc.initial)) {
                        desc.initial = new Date(desc.initial * 1000);
                    }

                    control.set({ allowGrowX : false });
                    break;

                case "CheckBox":
                    control = new qx.ui.form.CheckBox();

                    if (qx.lang.Type.isNumber(desc.initial)) {
                        desc.initial = desc.initial == 1;
                    }

                    break;

                case "Spinner":
                    control = new qx.ui.form.Spinner();

                    if (desc.min) {
                        control.setMinimum(desc.min);
                    }

                    if (desc.max) {
                        control.setMaximum(desc.max);
                    }

                    break;
                case "ComboTable":
                    var remoteModel = new dbtoria.db.RemoteTableModel(desc.tableId,[desc.idCol,desc.valueCol]);
                    control = new combotable.ComboTable(remoteModel);
                    break;
                case "SelectBox":
                    control = new qx.ui.form.SelectBox();
                    this._addListItems(control, desc.data);
                    break;

                case "MultiPick":
                    control = new dbtoria.ui.form.CheckBoxGroup();
                    control.set({
                        allowGrowY : false,
                        allowGrowX : true
                    });

                    this._addCheckItems(control, desc.data);
                    break;

                case "OpAndValue":
                    if (!qx.lang.Type.isArray(desc.initial)) {
                        desc.initial = [ desc.data[0], null ];
                    }

                    control = new dbtoria.ui.form.OpAndValue(desc.data, desc.initial[0], desc.initial[1]);

                    // do not set this twice
                    delete desc['initial'];
                    control.set({
                        allowGrowY : false,
                        allowGrowX : true
                    });

                    break;

                case "OpAndDate":
                    if (!qx.lang.Type.isArray(desc.initial)) {
                        desc.initial = [ desc.data[0], null ];
                    }

                    control = new dbtoria.ui.form.OpAndDate(desc.data, desc.initial[0], desc.initial[1]);

                    // do not set this twice
                    delete desc['initial'];
                    control.set({
                        allowGrowY : false,
                        allowGrowX : true
                    });

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

            if (qx.lang.Type.isObject(model)) {
                if (control.getModelSelection) {
                    control.addListener('changeSelection', function(e) {
                        var selected = control.getModelSelection();
                        var value;
                        if (desc.type == "SelectBox") {
                            value = selected.toArray()[0];
                        } else {
                            value = selected.toArray();
                        }
                        model[desc.name] = value;
                    },this);
                }
                else {
                    control.addListener('changeValue', function(e) {
                        var value = e.getData();
                        model[desc.name] = value;
                    },this);
                }
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
