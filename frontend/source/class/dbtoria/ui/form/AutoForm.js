/* ************************************************************************
   Copyright: 2009 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
              Fritz Zaucker <fritz.zaucker@oetiker.ch?
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
        var formData = this.__formData = {};
        var validationMgr = this.getValidationManager();
        var controlMap = this.__controlMap = {};
        for (var i=0; i<fl; i++) {
            var desc = formDesc[i];
            var trlab = desc.label.translate ? desc.label : this['tr'](desc.label);

            var item = controlMap[desc.name] =
                dbtoria.ui.form.ControlBuilder.createControl(desc, qx.lang.Function.bind(this.__formDataCallback, this));
            var control = item.control;

            this.add(control, trlab, null, desc.name);
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
                    var msg = this['tr'](desc.check.msg);
                    validationMgr.add(control,function(value,item){
                        var valid = rx.test(formData[name] || '');
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

    properties : {
        formDataChanged : {
            init     : false,
            check    : "Boolean",
            apply    : '_applyFormDataChanged',
            nullable : false
        }
    },

    members : {
        __formData : null,
        __controlMap: null,

        _applyFormDataChanged: function(newValue, oldValue) {
            this.debug('formDataChanged='+newValue);
        },

        __formDataCallback: function(key, value) {
            this.__formData[key] = value;
            this.setFormDataChanged(true);
        },

        /**
         * Return the form formData.
         *
         * @return {var} TODOC
         */
        getFormData : function() {
            return this.__formData;
        },

        clear: function() {
            for (var k in this.__controlMap) {
                this.__controlMap[k].setter(null);
            }
        },

        setFormData: function(dataMap) {
//            this.debug('setFormData() called');
            for (var k in dataMap) {
//                this.debug('Setting key='+k+', value='+dataMap[k]);
                this.__controlMap[k].setter(dataMap[k]);
            }
      }
    }
});
