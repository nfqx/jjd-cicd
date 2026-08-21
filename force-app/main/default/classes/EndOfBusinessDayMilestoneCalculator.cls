global class EndOfBusinessDayMilestoneCalculator implements Support.MilestoneTriggerTimeCalculator {   
    global Integer calculateMilestoneTriggerTime(String caseId, String milestoneTypeId) {
        // 1. Fetch the Case to get its assigned Business Hours
        Case currentCase = [SELECT Id, BusinessHoursId FROM Case WHERE Id = :caseId LIMIT 1];
        
        // 2. Fallback to default Org Business Hours if the Case doesn't have one assigned
        Id businessHoursId = currentCase.BusinessHoursId;
        if (businessHoursId == null) {
            BusinessHours defaultBH = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
            businessHoursId = defaultBH.Id;
        }
        
        // 3. Get the current time in the context of the business hours
        Datetime now = Datetime.now();
        
        // 4. Find the official end of the current business day
        // BusinessHours.nextStartDate finds the next open time. If we look 1 second before midnight, 
        // it helps us locate the correct closing boundary for today.
        Datetime endOfToday = Datetime.newInstance(now.year(), now.month(), now.day(), 23, 59, 59);
        Datetime nextStart = BusinessHours.nextStartDate(businessHoursId, endOfToday);
        
        // 5. Calculate the exact end of the business day
        // We find the last active business millisecond before the next start date
        Datetime endOfBusinessDay = BusinessHours.add(businessHoursId, nextStart, -1);
        
        // 6. Calculate the difference in minutes from right now
        Long millisecondsDiff = endOfBusinessDay.getTime() - now.getTime();
        Integer minutesRemaining = Integer.valueOf(millisecondsDiff / (1000 * 60));
        
        // 7. Return the minutes. Salesforce requires a positive integer above 0.
        return minutesRemaining > 0 ? minutesRemaining : 1; 
    }
}