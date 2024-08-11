/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2024 Piotr Kożuchowski
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
 * /
 * *
 */

@IsTest
public class MockTest {


    @IsTest
    static void shouldReturnAccountWithMockedReadonlyFields() {
        Account account = (Account) Mock.sObject(Account.SObjectType, new Map<String, Object>{
            'Name' => 'Test',
            'CreatedBy' => new User(
                LastName = 'Test User'
            ),
            'Contacts' => new List<Contact>{
                new Contact(
                    LastName = 'Test Contact'
                )
            }
        });

        Assert.areEqual('Test', account.Name);
        Assert.areEqual('Test User', account.CreatedBy.LastName);
        Assert.areEqual('Test Contact', account.Contacts[0].LastName);
    }

    @IsTest
    static void shouldReturnListOfAccountsWithMockedReadonlyFields() {
        List<Account> accounts = Mock.sObjects(Account.SObjectType, new List<Map<String, Object>>{
            new Map<String, Object>{
                'Name' => 'Test',
                'CreatedBy' => new User(
                    LastName = 'Test User'
                ),
                'Contacts' => new List<Contact>{
                    new Contact(
                        LastName = 'Test Contact'
                    )
                }
            }
        });

        Assert.areEqual(1, accounts.size());
        Assert.areEqual('Test', accounts[0].Name);
        Assert.areEqual('Test User', accounts[0].CreatedBy.LastName);
        Assert.areEqual('Test Contact', accounts[0].Contacts[0].LastName);
    }

    @IsTest
    static void shouldMockReadonlyFieldsOnChildren() {
        Account account = (Account) Mock.sObject(Account.SObjectType, new Map<String, Object>{
            'CreatedBy' => new Map<String, Object>{
                'CreatedDate' => Date.today()
            },
            'Contacts' => new List<Object>{
                new Map<String, Object>{
                    'CreatedDate' => Date.today()
                }
            }
        });

        Assert.areEqual(Date.today(), account.CreatedBy.CreatedDate);
        Assert.areEqual(Date.today(), account.Contacts[0].CreatedDate);
    }

    /*Method Mocking*/

    public Integer positiveRandom() {
        return Math.abs(Crypto.getRandomInteger());
    }

    public Integer random() {
        return Crypto.getRandomInteger();
    }

    @IsTest
    static void shouldMockAllResponses() {
        Integer expected = 1;

        MockTest util = (MockTest) Mock.response(MockTest.class, expected);
        Assert.areEqual(expected, util.random());
        Assert.areEqual(expected, util.positiveRandom());
    }

    @IsTest
    static void shouldMockOnlyRandom() {
        Integer expected = 1;

        MockTest util = (MockTest) Mock.response(MockTest.class, 'random', expected);
        Assert.areEqual(1, util.random());
        Assert.areEqual(null, util.positiveRandom());
    }

    @IsTest
    static void shouldHaveDifferentOutcomesForDifferentCalls() {
        MockTest util = (MockTest) Mock.response(MockTest.class, new Map<String, Object>{
            'random#1' => 1,
            'random#2' => 2,
            'random#3' => 3
        });
        Assert.areEqual(1, util.random());
        Assert.areEqual(2, util.random());
        Assert.areEqual(3, util.random());
    }

    @IsTest
    static void shouldThrowException() {
        String exceptionMsg = 'Test';
        try {
            MockTest util = (MockTest) Mock.response(MockTest.class, 'random', new MathException(exceptionMsg));
            util.random();
            Assert.fail();

        } catch (Exception e) {
            Assert.areEqual(exceptionMsg, e.getMessage());
        }
    }
}