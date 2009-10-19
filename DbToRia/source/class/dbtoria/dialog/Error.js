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
#asset(qx/icon/Tango/32/status/dialog-error.png)

************************************************************************ */

/**
 * This class provides an error dialog.
 * 
 * It takes an error string as parameter and displays it in a dialog box.
 * The class is a singleton. Only one dialog can be present at the same
 * time (modal window).
 */
qx.Class.define("dbtoria.dialog.Error", {
    type: "singleton",
    extend: qx.ui.window.Window,

    /*
    *****************************************************************************
	CONSTRUCTOR
    *****************************************************************************
    */
    
    construct: function() {
    
	// call super class
	this.base(arguments, this.tr("Error"));
    
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
	this.add(new qx.ui.basic.Image("qx/icon/Tango/32/status/dialog-error.png"), { row: 0, column: 0 });
	
	this.__errorLabel = new qx.ui.basic.Label().set({ font: "bold", rich: true });
	this.add(this.__errorLabel, { row: 0, column: 1 });
    
	// ok button
	var okButton = new qx.ui.form.Button(this.tr("ok")).set({
	    allowGrowX: false,
	    width: 70,
	    alignX: "left"
	});
    
	this.add(okButton, { row: 2, column: 1 });
    
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
	
	// errorLabel is the label containing the error message 
	__errorLabel: null,
	
	/**
	* Set the Error Message
	*
	* @param errorMessage {String} Error description
	*/
	setErrorMessage: function(errorMessage) {
	    
	    if(errorMessage.length < 100) {
		this.__errorLabel.setWidth(null);
	    }
	    else {
		this.__errorLabel.setWidth(400);
	    }
	    this.__errorLabel.setContent(errorMessage);
	},
	
	/**
	* Show Error
	* This function takes an error message an directly displays it.
	*
	* @param errorMessage {String} Error description
	*/
	showError : function(errorMessage) {
	    this.setErrorMessage(errorMessage);
	    this.open();
	}
    }
});