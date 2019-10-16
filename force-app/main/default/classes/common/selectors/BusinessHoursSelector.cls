/**
* MIT License
*
* Copyright (c) 2018 Piotr Kożuchowski
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

/**
 * Selector Layer for Business Hours.
 * Results are cached for better performance and SOQL Limits savings.
 * @see BusinessHoursSelectorTest
 */
public inherited sharing class BusinessHoursSelector {
    private static SObjectCache cache = new SObjectCache([
            SELECT Id,
                    Name,
                    IsDefault,
                    IsActive,
                    MondayStartTime,
                    MondayEndTime,
                    TuesdayStartTime,
                    TuesdayEndTime,
                    WednesdayStartTime,
                    WednesdayEndTime,
                    ThursdayStartTime,
                    ThursdayEndTime,
                    FridayStartTime,
                    FridayEndTime,
                    SaturdayStartTime,
                    SaturdayEndTime,
                    SundayStartTime,
                    SundayEndTime
            FROM BusinessHours
            WHERE IsActive = TRUE

    ], new List<SObjectField>{
            BusinessHours.Id,
            BusinessHours.Name,
            BusinessHours.IsDefault
    });


    /**
     * @return Default Business Hours for running environment.
     */
    public BusinessHours selectDefault() {
        return (BusinessHours) cache.retrieveFirst(BusinessHours.IsDefault, true);
    }


    /**
     * @return Active Business Hours with given name
     */
    public BusinessHours selectByName(String name) {
        return (BusinessHours) cache.retrieveFirst(BusinessHours.Name, name);
    }


    /**
     * @return Active Business Hours with given id
     */
    public BusinessHours selectById(Id businessHoursId) {
        return (BusinessHours) cache.retrieveFirst(BusinessHours.Id, businessHoursId);
    }

    /**
     * @return Active Business Hours with given ids
     */
    public BusinessHours[] selectByIds(Set<Id> businessHoursIds) {
        return cache.retrieve(BusinessHours.Id, new List<Id>(businessHoursIds));
    }

    /**
     * @return Active Business Hours with given ids
     */
    public Map<Id, BusinessHours> selectMapByIds(Set<Id> businessHoursIds) {
        return new Map<Id, BusinessHours>(selectByIds(businessHoursIds));
    }
}