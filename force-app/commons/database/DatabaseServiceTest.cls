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
private class DatabaseServiceTest {

    @IsTest
    static void testDML() {
        Account acc = new Account(
                Name = 'Test'
        );


        for (Sharing s : Sharing.values()) {
            DatabaseService databaseService = new DatabaseService()
                    .setSharing(s)
                    .setDMLOptions(new DMLOptionsBuilder()
                            .allowDuplicates(true)
                            .build()
                    );

            databaseService.doInsert(acc);
            databaseService.doUpdate(acc);
            databaseService.doUpsert(acc, Account.Id);
            databaseService.doDelete(acc);
            databaseService.doUndelete(acc);
            databaseService.query('SELECT ID FROM Account');
        }
    }

    @IsTest
    static void testQuery() {
        DatabaseService databaseService = new DatabaseService();

        List<User> expected = [SELECT Id FROM User LIMIT 50];

        for (Sharing s : Sharing.values()) {
            databaseService.setSharing(s);
            List<User> actual = databaseService.query('SELECT ID FROM User WHERE ID IN :users', new Map<String, Object>{'users' => expected});

            System.assertEquals(
                    new Map<Id, User>(expected).keySet(),
                    new Map<Id, User>(actual).keySet()
            );
        }
    }

    @IsTest
    static void testQueryLocator() {
        DatabaseService databaseService = new DatabaseService();

        List<User> expected = [SELECT Id FROM User LIMIT 50];

        for (Sharing s : Sharing.values()) {
            databaseService.setSharing(s);
            Database.QueryLocator queryLocator = databaseService.getQueryLocator('SELECT ID FROM User WHERE ID IN :users', new Map<String, Object>{'users' => expected});
            Database.QueryLocatorIterator it = queryLocator.iterator();

            List<User> actual = new List<User>();
            while(it.hasNext()){
                User user = (User) it.next();
                actual.add(user);
            }

            System.assertEquals(
                    new Map<Id, User>(expected).keySet(),
                    new Map<Id, User>(actual).keySet()
            );
        }
    }
}