@IsTest
public with sharing class ConvertLeadMobileControllerTest {

	@TestSetup
	private static void makeData(){
        Lead lead = new Lead(LastName='unittest', Company='unittest');
        insert lead;
    }

    @IsTest
    public static void convertLeadAutomaticTest() {
        Test.startTest();
            Lead leadConvert = [SELECT id FROM Lead LIMIT 1];
            String resultText =ConvertLeadMobileController.convertLeadAutomatic(leadConvert.id);
            System.assert(resultText.contains('ERROR:'), 'Error on validation rule required');
        Test.stopTest();
    }

}