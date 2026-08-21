@isTest
private class EndOfBusinessDayMilestoneCalculatorTest {
    @isTest
    static void testMilestoneCalculation() {
        // Fetch default business hours
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        
        // Create test Case
        Case testCase = new Case(
            Subject = 'Test Milestone Case',
            BusinessHoursId = bh.Id
        );
        insert testCase;
        
        // Instantiate the calculator
        EndOfBusinessDayMilestoneCalculator calculator = new EndOfBusinessDayMilestoneCalculator();
        
        Test.startTest();
        // Execute calculation (passing dummy ID for milestone type)
        Integer minutes = calculator.calculateMilestoneTriggerTime(testCase.Id, '00G000000000000');
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, minutes, 'The calculator should return a minute value.');
        System.assert(minutes > 0, 'The calculated minutes must be greater than zero.');
    }
}