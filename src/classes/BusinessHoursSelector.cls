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
 */
public class BusinessHoursSelector {
    private static Map<String, BusinessHours> cachedHours = new Map<String, BusinessHours>();
    private static BusinessHours defaultHours;
    static {
        List<BusinessHours> businessHours = [
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
        ];

        for (BusinessHours hours : businessHours) {
            cachedHours.put(hours.Name, hours);
            cachedHours.put(hours.Id, hours);

            if (hours.IsDefault) {
                defaultHours = hours;
            }
        }
    }


    /**
     * @return Default Business Hours for running environment.
     */
    public BusinessHours selectDefault() {
        return defaultHours;
    }


    /**
     * @return Active Business Hours with given name
     */
    public BusinessHours selectByName(String name) {
        return cachedHours.get(name);
    }


    /**
     * @return Active Business Hours with given id
     */
    public BusinessHours selectById(Id businessHoursId) {
        return cachedHours.get(businessHoursId);
    }

    /**
     * @return Active Business Hours with given ids
     */
    public BusinessHours[] selectByIds(Set<Id> businessHoursIds) {
        List<BusinessHours> result = new List<BusinessHours>();

        for (Id businessHoursId : businessHoursIds) {
            result.add(cachedHours.get(businessHoursId));
        }

        return result;
    }

    /**
     * @return Active Business Hours with given ids
     */
    public Map<Id, BusinessHours> selectMapByIds(Set<Id> businessHoursIds) {
        return new Map<Id, BusinessHours>(selectByIds(businessHoursIds));
    }
}