#!/usr/bin/phantomjs --ignore-ssl-errors=true

var web_browser = require('webpage').create(),
	system = require('system'),
	TIMEOUT_MS = 10000

if( system.args.length > 1 )
{
	web_browser.open( system.args[1] ,function(status) {
		if(status == 'success')
			web_browser.render( system.args[1].split('/')[2] + '.png' )
		console.log(status)
		phantom.exit(0)
	} )
	setTimeout( function() { console.log('timeout'); phantom.exit() }, TIMEOUT_MS )
}
else
{
	console.log("usage:")
	console.log(system.args[0] + " https://www.site.com/")
	phantom.exit(1)
}