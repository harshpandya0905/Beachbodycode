@isTest
global class  CPM_HTTPCalloutMock_Test implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
		res.setHeader('Content-Type','application/json');
        res.setStatusCode(200);
        res.setBody('{"accessToken":"thisIsAnAccessToken"}');
        System.debug('gets here');
        
        return res;
    }

}