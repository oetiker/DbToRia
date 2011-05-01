/* ************************************************************************
   Copyright: 2009 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
              Fritz Zaucker <fritz.zaucker@oetiker.ch?
   Utf8Check: äöü
************************************************************************ */

/* ************************************************************************
************************************************************************ */

qx.Class.define("dbtoria.ui.form.ComboTable", {
    extend : combotable.ComboTable,
    include : [ dbtoria.ui.form.MControlProperties ],

    /**
     * @param tableModel {} table model to use.
     *
     * Create a customized comboTable.
     *
     */
    construct : function(desc) {
        var l = {};
        l[desc.idCol] = 'id';
        l[desc.valueCol] = 'value';
        var tableModel = new dbtoria.data.RemoteTableModel(desc.tableId,
                                                           [desc.idCol,desc.valueCol], l);
        this.base(arguments, tableModel);
    },

    members : {
        setter: function(value) {
            if (this.getModel() != null) {
                return;
            }
            if (value == null || value.id == undefined || value.id == null) {
                this.setModel(null);
                this.setValue(qx.locale.Manager.tr('Select'));
            }
            else {
                this.setModel(value.id);
                this.setValue(value.text);
            }
        },

        clear: function() {
            this.setModel(null);
            this.setValue(qx.locale.Manager.tr('Select'));
        },

        validator: function() {
            return function(value,control){
                if (value == qx.locale.Manager.tr('Select') && !control.getRequired()) {
                    control.setValid(true);
                    return true;
                }
                var msg = qx.locale.Manager.tr('This field must not be undefined.');
                var valid = (value != qx.locale.Manager.tr('Select'));
                if (!valid){
                    control.setInvalidMessage(msg);
                    control.setValid(valid);
                }
                return valid;
            };
        }

    }

});
