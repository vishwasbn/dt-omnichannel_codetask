@isTest
global class Fleet_ECC_Mock_Response implements HttpCalloutMock  {
    global HTTPResponse respond(HTTPRequest req) {
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"status": "success","message": "record added to SQS queue successfully"}');
        res.setStatusCode(200);
        return res;
    }
}