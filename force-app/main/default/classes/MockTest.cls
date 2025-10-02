@isTest
public with sharing class MockTest {

	public static HttpResponse mockTokenOk(){
		HttpResponse mockTest = new HttpResponse();
		mockTest.setStatus('OK');
		mockTest.setStatusCode(200);
		mockTest.setBody('00000000000');
		return mockTest;
	}

	public static HttpResponse mockCreate(){
		HttpResponse mockTest = new HttpResponse();
		mockTest.setStatus('OK');
		mockTest.setStatusCode(200);
		mockTest.setBody('{"error": {"message": "test", "code": "1"},"data": "test"}');
		return mockTest;
	}
}