/* ************************************************************************

   Copyrigtht: OETIKER+PARTNER AG
   License:    GPL
   Authors:    Tobias Oetiker
   Utf8Check:  äöü

************************************************************************ */

/**
 * The checkbox container handles a collection of {@link qx.ui.form.CheckBox} instances.
 * Providing the same interface as a {@link qx.ui.form.List} object.
 *
 * This widget takes care of the layout of the added items.
 */
qx.Class.define("dbtoria.ui.form.CheckBoxGroup", {
    extend : qx.ui.core.Widget,
    implement : [ qx.ui.form.IForm, qx.ui.form.IModelSelection, qx.ui.core.ISingleSelection ],

    include : [
    // have layout handling
    qx.ui.core.MLayoutHandling,

    // provide access to the 'model' values of the checkbox items
    qx.ui.form.MModelSelection,

    // form methods
    qx.ui.form.MForm ],


    /**
                   * @param layout {qx.ui.layout.Abstract} The new layout or
                   *     <code>null</code> to reset the layout.
                   */
    construct : function(layout) {
        this.base(arguments);

        // if no layout is given, use the default layout (VBox)
        this.set({ layout : layout || new qx.ui.layout.Flow(8, 3) });
        this.__selected = new qx.data.Array();
        this.setAllowGrowY(true);
    },

    events : {
        /**
                                     * Fires after the selection was modified
                                     */
        "changeSelection" : "qx.event.type.Data"
    },

    members : {
        /*
                                    ---------------------------------------------------------------------------
                                      SELECTION
                                    ---------------------------------------------------------------------------
                                    */

        __selected : null,


        /**
         * set focus to first checkbox
         *
         * @return {void} 
         */
        focus : function() {
            var firstKid = this._getChildren()[0];

            if (firstKid) {
                firstKid.focus();
            }
        },


        /**
         * Adds a new child widget.
         * 
         * The supported keys of the layout options map depend on the layout manager
         * used to position the widget. The options are documented in the class
         * documentation of each layout manager {@link qx.ui.layout}.
         *
         * @param child {LayoutItem} the widget to add.
         * @param options {Map ? null} Optional layout data for widget.
         * @return {void} 
         */
        add : function(child, options) {
            child.addListener('changeValue', function(e) {
                var o = e.getOldData();
                var n = e.getData();

                if (n && !o) {
                    this.__selected.unshift(child);
                }

                if (!n && o) {
                    this.__selected.remove(child);
                }

                this.fireDataEvent('changeSelection', this.__selected.toArray());
            },
            this);

            this._add(child, options);
        },


        /**
         * Returns an array of currently selected items.
         * 
         * Note: The result is only a set of selected items, so the order can
         * differ from the sequence in which the items were added.
         *
         * @return {qx.ui.core.Widget[]} List of items.
         */
        getSelection : function() {
            return this.__selected.toArray();
        },


        /**
         * Replaces current selection with the given items.
         *
         * @param items {qx.ui.core.Widget[]} Items to select.
         * @return {void} 
         */
        setSelection : function(items) {
            var kids = this._getChildren();

            for (var i=0; i<kids.length; i++) {
                var ok = false;

                for (var ii=0; ii<items.length; ii++) {
                    if (kids[i] === items[ii]) {
                        ok = true;
                    }
                }

                kids[i].setValue(ok);
            }
        },


        /**
         * Clears the whole selection at once.
         *
         * @return {void} 
         */
        resetSelection : function() {
            var kids = this._getChildren();

            for (var i=0; i<kids.length; i++) {
                kids[i].setValue(false);
            }
        },


        /**
         * Detects whether the given item is currently selected.
         *
         * @param item {qx.ui.core.Widget} Any valid selectable item
         * @return {Boolean} Whether the item is selected.
         */
        isSelected : function(item) {
            return item.getValue();
        },


        /**
         * Whether the selection is empty.
         *
         * @return {Boolean} Whether the selection is empty.
         */
        isSelectionEmpty : function() {
            return this.__selected.length == 0;
        },


        /**
         * Returns all elements which are selectable.
         *
         * @return {qx.ui.core.Widget[]} The contained items.
         */
        getSelectables : function() {
            return this._getChildren();
        }
    }
});
