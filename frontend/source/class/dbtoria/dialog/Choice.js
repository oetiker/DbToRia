/* ************************************************************************

  DbToRia - Database to Rich Internet Application
  
  http://www.dbtoria.org

   Copyright:
    2009 David Angleitner, Switzerland
    
   License:
    GPL: http://www.gnu.org/licenses/gpl-2.0.html

   Authors:
    * David Angleitner

************************************************************************ */

/* ************************************************************************

#asset(dbtoria/*)
#asset(qx/icon/${qx.icontheme}/32/status/dialog-information.png)

************************************************************************ */

/**
 * This class provides a dialog with a choice for the user.
 * 
 * It takes an message string and two options as parameter and displays it in a dialog box.
 * The class is a singleton. Only one dialog can be present at the same
 * time (modal window).
 */
qx.Class.define("dbtoria.dialog.Choice", {
    type: "singleton",
    extend: qx.ui.window.Window,

    /*
    *****************************************************************************
	CONSTRUCTOR
    *****************************************************************************
    */
    
    construct: function() {
    
	// call super class
	this.base(arguments, this.tr("Dialog"));
    
	// disable window resizing and set modal
	this.set({
	    showMinimize: false,
	    showMaximize: false,
	    movable: false,
	    resizable: false,
	    showClose: false,
	    contentPadding: 20,
	    modal: true
	});
	
	this.getApplicationRoot().set({
	    blockerColor: '#bfbfbf',
	    blockerOpacity: 0.8
	});
	
	// center window in browser
	this.addListener("appear", function() {
	    this.center();
	}, this);
    
	// layout properties
	var layout = new qx.ui.layout.Grid(20, 5);
	layout.setColumnAlign(1, "center", "middle");

	this.setLayout(layout);
    
	// generate username and password labels and fields
	this.add(new qx.ui.basic.Image("icon/32/status/dialog-information.png"), { row: 0, column: 0 });
	
	this.__msgLabel = new qx.ui.basic.Label().set({ font: "bold", rich: true });
	this.add(this.__errorLabel, { row: 0, column: 1 });
    
	// ok button
	var button1 = new qx.ui.form.Button().set({
	    allowGrowX: false,
	    width: 70,
	    alignX: "left"
	});
	
	// ok button
	var button2 = new qx.ui.form.Button().set({
	    allowGrowX: false,
	    width: 70,
	    alignX: "left"
	});
    
	this.add(button1, { row: 2, column: 1 });
	this.add(button2, { row: 2, column: 2 });
    
	// close window on button click
	okButton.addListener("execute", function(e) {
	    this.close();
	}, this);
    },
    
     /*
    *****************************************************************************
       MEMBERS
    *****************************************************************************
    */
    
    members: {
	
	// msgLabel is the label containing the dialog message 
	__msgLabel: null,
	
	/**
	* Set the message
	*
	* @param message {String} Dialog description
	*/
	setMessage: function(message) {
	    
	    if(message.length < 100) {
		this.__msgLabel.setWidth(null);
	    }
	    else {
		this.__msgLabel.setWidth(400);
	    }
	    this.__msgLabel.setContent(message);
	},
	
	/**
	* Show 
	* This function takes a message and directly displays it.
	*
	* @param message {String} Dialog description
	*/
	show : function(message) {
	    this.setMessage(message);
	    this.open();
	}
    }
});
