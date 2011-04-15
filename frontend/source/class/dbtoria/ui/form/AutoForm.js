/* ************************************************************************
   Copyright: 2009 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
   Utf8Check: äöü
************************************************************************ */

/* ************************************************************************
************************************************************************ */

qx.Class.define("dbtoria.ui.form.AutoForm", {
    extend : qx.ui.form.Form,
    include : [ qx.locale.MTranslation ],


    /**
     * @param formDesc {formDescription[]} Form description array.
     *
     * Create a form based on a form descriptions using {@link dbtoria.ui.form.ControlBuilder}.
     *
     * Control descriptions can contain a check property with the
     * the keys 'msg' and 'rx' the rx is checked on value change
     * and the label is shown as invalid message
     *
     */
    construct : function(formDesc) {
        this.base(arguments);
        var fl = formDesc.length;
        var model = this.__model = {};

        var form = this;
        var validationMgr = form.getValidationManager();
        for (var i=0; i<fl; i++) {
            var desc = formDesc[i];
            var control;
            var trlab = desc.label.translate ? desc.label : this['tr'](desc.label);

            switch(desc.type)
            {
                case "GroupHeader": /* from nequal, not yet used in DbToRia */
                    form.addGroupHeader(trlab);
                    continue;

                default:
                    control = dbtoria.ui.form.ControlBuilder.createControl(desc, model);
                    break;
            }
            form.add(control, trlab, null, desc.name);
            if (desc.hasOwnProperty('required')) {
                control.set({
                    required: true,
                    requiredInvalidMessage: this.tr('This field is required')
                });
            }
            if (desc.hasOwnProperty('check')) {
                (function(){ /* give use local context - function factory */
                    var rx = new RegExp(desc.check.rx);
                    var name = desc.name;
                    var msg = form['tr'](desc.check.msg);
                    validationMgr.add(control,function(value,item){
                        var valid = rx.test(model[name] || '');
                        if (!valid){
                            item.setInvalidMessage(msg);
                            item.setValid(valid);
                        }
                        return valid;
                    });
                })();
            }
        }
    },

    members : {
        __model : null,


        /**
         * Return the form model.
         *
         * @return {var} TODOC
         */
        getModel : function() {
            return this.__model;
        }
    }
});
