/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2023 Piotr Kożuchowski
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
 *  Please find newest source code at https://github.com/pkozuchowski/Apex-Opensource-Library
 * /
 */

@IsTest
private class ConditionsTest {
    private static final Condition isTrue = new TrueCondition();
    private static final Condition isFalse = new FalseCondition();

    private class TrueCondition implements Condition {
        public Boolean isTrue(Object item) {
            return true;
        }
    }

    private class FalseCondition implements Condition {
        public Boolean isTrue(Object item) {
            return false;
        }
    }

    @IsTest
    static void testOrConditions() {
        Conditions c = new Conditions();

        Assert.areEqual(true, c.ORs(isFalse, isTrue).isTrue(null));
        Assert.areEqual(true, c.ORs(isFalse, isTrue, isFalse).isTrue(null));
        Assert.areEqual(true, c.ORs(isFalse, isTrue, isFalse, isFalse).isTrue(null));
        Assert.areEqual(false, c.ORs(isFalse, isFalse, isFalse, isFalse, isFalse).isTrue(null));
    }

    @IsTest
    static void testANDConditions() {
        Conditions c = new Conditions();

        Assert.areEqual(false, c.ANDs(isFalse, isTrue).isTrue(null));
        Assert.areEqual(false, c.ANDs(isFalse, isTrue, isFalse).isTrue(null));
        Assert.areEqual(false, c.ANDs(isFalse, isTrue, isFalse, isFalse).isTrue(null));
        Assert.areEqual(true, c.ANDs(isTrue, isTrue, isTrue, isTrue, isTrue).isTrue(null));
    }
}