/**
* MIT License
*
* Copyright (c) 2019 Piotr Kożuchowski
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
public class SelectorTest {
    private class ExampleSelector extends Selector {
        private ExampleSelector() {
            super(new List<SObjectField>{
                    User.Id,
                    User.Name,
                    User.Email,
                    User.Username
            }, User.SObjectType);
        }
    }

    @IsTest
    static void testSelectById() {
        User user = (User) new ExampleSelector().byId(UserInfo.getUserId());

        System.assertEquals(UserInfo.getUserId(), user.Id);
        System.assertEquals(UserInfo.getName(), user.Name);
        System.assertEquals(UserInfo.getUserEmail(), user.Email);
    }

    @IsTest
    static void testSelectByField() {
        User user = (User) new ExampleSelector().oneRecordByField(User.Username, '=', UserInfo.getUserName());

        System.assertEquals(UserInfo.getUserId(), user.Id);
        System.assertEquals(UserInfo.getName(), user.Name);
        System.assertEquals(UserInfo.getUserEmail(), user.Email);
    }

    @IsTest
    static void testSelectAll() {
        assertEquals(
                ([SELECT Id FROM User]),
                new ExampleSelector().all()
        );
    }

    @IsTest
    static void testSelectOne() {
        User usr = (User) new ExampleSelector().one();
        System.assertNotEquals(null, usr);
    }

    public static void assertEquals(SObject[] expected, SObject[] actual) {
        System.assertEquals(
                new Map<Id, SObject>(expected).keySet(),
                new Map<Id, SObject>(actual).keySet()
        );
    }

    @IsTest
    static void queryBuilderCoverage() {
        new SelectorQuery()
                .selectField(Account.Id)
                .selectField('Name')
                .selectFields(new List<SObjectField>{Account.Id})
                .selectFields(new List<String>{'Id'})
                .addChildFields(new List<SObjectField>{Contact.Id}, 'Contacts')
                .fromObject(Account.SObjectType)
                .setWhere('Name != NULL')
                .setGroupBy('Name')
                .setHaving('')
                .setOrderBy('Name')
                .setOffset(0)
                .setLimit(100);
    }
}