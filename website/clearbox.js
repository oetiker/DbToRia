


/*                                                                                                                                                                              
	clearbox by pyro
	
	script home:		http://www.clearbox.hu
	email:			clearboxjs(at)gmail(dot)com
	MSN:			pyro(at)radiomax(dot)hu
	support forum 1:	http://www.sg.hu/listazas.php3?id=1172325655

	LICENSZ FELTÉTELEK:

	A clearbox szabadon felhasználható bármilyen nem kereskedelmi jellegû honlapon, 
	tehát azokon amelyek nem kereskedelmi tevékenységet folytató cégek, vállalatok 
	oldalai; nem tartalmaznak kereskedelmi jellegû szolgáltatást vagy termék(ek) 
	eladás(á)t, illetve reklámozás(á)t. A kereskedelmi jellegû honlapokon való 
	felhasználásáról érdeklõdj a készítõnél! A clearbox forráskódja nem módosítható. 
	A clearbox a készítõ beleegyezése nélkül pénzért harmadik félnek tovább nem adható!

	LICENSE:

	ClearBox can be used free for all non-commercial web pages. For commercial using, please contact with the developer:

	George Krupa
*/



var	CB_ScriptDir='clearbox';
var	CB_Language='en';



//
//	ClearBox load:
//

	var CB_Scripts = document.getElementsByTagName('script');
	for(i=0;i<CB_Scripts.length;i++){
		if (CB_Scripts[i].getAttribute('src')){
			var q=CB_Scripts[i].getAttribute('src');
			if(q.match('clearbox.js')){
				var url = q.split('clearbox.js');
				var path = url[0];
				var query = url[1].substring(1);
				var pars = query.split('&');
				for(j=0; j<pars.length; j++) {
					par = pars[j].split('=');
					switch(par[0]) {
						case 'config': {
							CB_Config = par[1];
							break;
						}
						case 'dir': {
							CB_ScriptDir = par[1];
							break;
						}
						case 'lng': {
							CB_Language = par[1];
							break;
						}
					}
				}
			}
		}
	}

	if(!CB_Config){
		var CB_Config='default';
	}

	document.write('<link rel="stylesheet" type="text/css" href="'+CB_ScriptDir+'/config/'+CB_Config+'/cb_style.css" />');
	document.write('<script type="text/javascript" src="'+CB_ScriptDir+'/config/'+CB_Config+'/cb_config.js"></script>');
	document.write('<script type="text/javascript" src="'+CB_ScriptDir+'/language/'+CB_Language+'/cb_language.js"></script>');
	document.write('<script type="text/javascript" src="'+CB_ScriptDir+'/core/cb_core.js"></script>');