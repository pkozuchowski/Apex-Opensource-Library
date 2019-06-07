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
@IsTest(IsParallel=true)
private class ProfileSelectorTest {

    @IsTest
    static void testProfileSelectorReturnsStandardUser() {
        Profile stdUser = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        System.assertEquals(new ProfileSelector().selectByName('Standard User').Id, stdUser.Id);
    }

    @IsTest
    static void testProfileSelectorReturnsStandardUserById() {
        Profile stdUser = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        System.assertEquals(new ProfileSelector().selectById(stdUser.Id).Id, stdUser.Id);
    }

    @IsTest
    static void testSelectByIds() {
        Map<Id, Profile> expected = new Map<Id, Profile>([
                SELECT Id
                FROM Profile
                WHERE Name IN ('Standard User', 'System Administrator')
        ]);
        Map<Id, Profile> actual = new Map<Id, Profile>(new ProfileSelector().selectByIds(expected.keySet()));

        System.assertEquals(expected.keySet(), actual.keySet());
    }

    @IsTest
    static void testSelectByNames() {
        Map<Id, Profile> expected = new Map<Id, Profile>([
                SELECT Id
                FROM Profile
                WHERE Name IN ('Standard User', 'System Administrator')
        ]);
        Map<Id, Profile> actual = new Map<Id, Profile>(new ProfileSelector().selectByNames(
                new Set<String>{'Standard User', 'System Administrator'}
        ));

        System.assertEquals(expected.keySet(), actual.keySet());
    }
}