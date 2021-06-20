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
 * @see BusinessHoursQueryTest
 */
public inherited sharing class BusinessHoursQuery extends Query {

    /**
     * Cache all Business Hours on first query to save SOQL limits
     */
    static {
        new BusinessHoursQuery().byField(BusinessHours.IsActive, '=', true).getList();
    }

    public BusinessHoursQuery() {
        super(new List<String>{
            'Id',
            'Name',
            'IsDefault',
            'IsActive',
            'MondayStartTime',
            'MondayEndTime',
            'TuesdayStartTime',
            'TuesdayEndTime',
            'WednesdayStartTime',
            'WednesdayEndTime',
            'ThursdayStartTime',
            'ThursdayEndTime',
            'FridayStartTime',
            'FridayEndTime',
            'SaturdayStartTime',
            'SaturdayEndTime',
            'SundayStartTime',
            'SundayEndTime'
        }, BusinessHours.SObjectType);
    }


    /**
     * @return Active Business Hours with given name
     */
    public QueryObject byDefault(Boolean isDefault) {
        return byField(BusinessHours.IsDefault, '=', isDefault);
    }


    /**
     * @return Active Business Hours with given name
     */
    public QueryObject byName(String name) {
        return byName(new Set<String>{name});
    }

    /**
     * @return Active Business Hours with given name
     */
    public QueryObject byName(Set<String> names) {
        return (QueryObject) byField(BusinessHours.Name, 'IN', names);
    }


    protected override Set<String> getFieldsToCacheBy() {
        return new Set<String>{
            'Id',
            'Name'
        };
    }
}