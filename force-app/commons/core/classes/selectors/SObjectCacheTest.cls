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
private class SObjectCacheTest {
    static List<Account> accounts = new List<Account>{
            new Account(Id = '001000000000000', Name = 'Test Account 0'),
            new Account(Id = '001000000000001', Name = 'Test Account 1'),
            new Account(Id = '001000000000002', Name = 'Test Account 2'),
            new Account(Id = '001000000000003', Name = 'Enterprise Account'),
            new Account(Id = '001000000000004', Name = 'Enterprise Account'),
            new Account(Id = '001000000000005', Name = 'Enterprise Account'),
            new Account(Id = '001000000000006', Name = 'Enterprise Account'),
            new Account(Id = '001000000000007', Name = 'Test Account 7'),
            new Account(Id = '001000000000008', Name = 'Test Account 8')
    };
    static SObjectCache cache = new SObjectCache(accounts, new List<SObjectField>{
            Account.Id,
            Account.Name
    });


    /**
     *@description
     * Cache will index sobjects by stored field. Retrieve will return only sobjects with the specified field value.
     */
    @IsTest
    static void testCacheByUniqueValue() {
        for (Account acc : accounts) {
            List<Account> cachedAccounts = cache.retrieve(Account.Id, acc.Id);
            System.assertEquals(1, cachedAccounts.size());
            System.assertEquals(acc.Id, cachedAccounts[0].Id);
        }
    }

    /**
     *@description
     * When cached field is not unique, Cache should return all sobjects with specified value.
     */
    @IsTest
    static void whenCachedFieldIsNotUniqueThenAllSObjectsWithGivenValueAreRetrieved() {
        List<Account> enterpriseAccounts = cache.retrieve(Account.Name, 'Enterprise Account');

        System.assertNotEquals(null, enterpriseAccounts);
        System.assertEquals(4, enterpriseAccounts.size());
        System.assertEquals(
                new Set<Id>{
                        '001000000000003',
                        '001000000000004',
                        '001000000000005',
                        '001000000000006'
                },
                new Map<Id, Account>(enterpriseAccounts).keySet()
        );
    }

    /**
     *@description
     * When multiple values are specified, single result list is returned with sobjects cached by specified values
     */
    @IsTest
    static void testCacheByMultipleValue() {
        List<Account> accounts = cache.retrieveAll(Account.Name, new List<Object>{
                'Enterprise Account',
                'Test Account 0',
                'Test Account 1'
        });

        System.assertEquals(6, accounts.size());
        System.assertEquals(
                new Set<Id>{
                        '001000000000000',
                        '001000000000001',
                        '001000000000003',
                        '001000000000004',
                        '001000000000005',
                        '001000000000006'
                },
                new Map<Id, Account>(accounts).keySet()
        );
    }

    /**
     *@description
     * Cache should return empty list when SObject field is retrieved that was not cached beforehand
     */
    @IsTest
    static void testCacheDoesNotThrowNPEOnRetrieve() {
        List<Account> accounts = cache.retrieve(Account.BillingCountry, 'Test Country');
        System.assertNotEquals(null, accounts);
        System.assertEquals(0, accounts.size());
    }

    /**
     *@description
     * retriveFirst returns first SObject with given field value or null
     */
    @IsTest
    static void testRetrieveFirst() {
        System.assertEquals('001000000000003', cache.retrieveFirst(Account.Name, 'Enterprise Account').Id);
        System.assertEquals(null, cache.retrieveFirst(Account.Name, 'Other'));
    }
}