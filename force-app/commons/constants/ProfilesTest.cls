/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2022 Piotr Kożuchowski
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
*/

@IsTest(IsParallel=true)
private class ProfilesTest {

    @IsTest
    static void shouldCacheQueryResultsToPreserveLimits() {
        Profile sysAdmin = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'];

        Test.startTest();
        System.assertEquals(sysAdmin.Id, Profiles.SYSTEM_ADMINISTRATOR.Id);
        System.assertEquals(sysAdmin.Name, Profiles.SYSTEM_ADMINISTRATOR.Name);
        Assert.isNotNull(Profiles.STANDARD_USER.Name);
        System.assertEquals(1, Limits.getQueries(), 'Consecutive calls should not use more queries');
        Test.stopTest();
    }

    @IsTest
    static void coverageTest() {
        System.assertNotEquals(null, Profiles.SYSTEM_ADMINISTRATOR.Id);
        System.assertNotEquals(null, Profiles.STANDARD_USER.Id);
    }
}