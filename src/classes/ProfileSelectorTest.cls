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
@IsTest
private class ProfileSelectorTest {

    @IsTest
    static void testProfileSelectorReturnsSystemAdminId() {
        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        System.assertEquals(new ProfileSelector().getProfileIdByName('System Administrator'), sysAdmin.Id);
    }

    @IsTest
    static void testProfileSelectorReturnsStandardUser() {
        Profile stdUser = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        System.assertEquals(new ProfileSelector().getProfileByName('Standard User').Id, stdUser.Id);
    }

    @IsTest
    static void testProfileSelectorReturnsStandardUserById() {
        Profile stdUser = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        System.assertEquals(new ProfileSelector().getProfileById(stdUser.Id).Id, stdUser.Id);
    }

    @IsTest
    static void testProfileSelectorReturnsStandardUserNameById() {
        Profile stdUser = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        System.assertEquals(new ProfileSelector().getProfileNameById(stdUser.Id), 'Standard User');
    }
}