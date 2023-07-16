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

/**
 * Factory class for Condition implementations.
 */
public virtual inherited sharing class Conditions {

    /**
     * Creates filter which returns true if all of the filters return true
     */
    public Condition ANDs(Condition f1, Condition f2) {
        return ANDs(new List<Condition>{f1, f2});
    }
    public Condition ANDs(Condition f1, Condition f2, Condition f3) {
        return ANDs(new List<Condition>{f1, f2, f3});
    }
    public Condition ANDs(Condition f1, Condition f2, Condition f3, Condition f4) {
        return ANDs(new List<Condition>{f1, f2, f3, f4});
    }
    public Condition ANDs(Condition f1, Condition f2, Condition f3, Condition f4, Condition f5) {
        return ANDs(new List<Condition>{f1, f2, f3, f4, f5});
    }
    public Condition ANDs(Condition[] conditions) {
        return new ANDCondition(conditions);
    }

    /**
     * Creates filter which returns true if any of the filters return true
     */
    public Condition ORs(Condition f1, Condition f2) {
        return ORs(new List<Condition>{f1, f2});
    }
    public Condition ORs(Condition f1, Condition f2, Condition f3) {
        return ORs(new List<Condition>{f1, f2, f3});
    }
    public Condition ORs(Condition f1, Condition f2, Condition f3, Condition f4) {
        return ORs(new List<Condition>{f1, f2, f3, f4});
    }
    public Condition ORs(Condition f1, Condition f2, Condition f3, Condition f4, Condition f5) {
        return ORs(new List<Condition>{f1, f2, f3, f4, f5});
    }
    public Condition ORs(Condition[] conditions) {
        return new ORCondition(conditions);
    }


    /**
     * Composite Condition used for creating nested AND and ORs conditions
     */
    private abstract class CompositeCondition implements Condition {
        protected Condition[] conditions;

        public CompositeCondition(Condition[] conditions) {
            this.conditions = conditions;
        }
    }

    /**
     * Returns true if any of the composite filters return true;
     */
    private class ANDCondition extends CompositeCondition {

        public ANDCondition(Condition[] conditions) {
            super(conditions);
        }

        public Boolean isTrue(Object item) {
            for (Integer i = 0, j = conditions.size(); i < j; ++i) {
                if (!conditions[i].isTrue(item)) return false;
            }

            return true;
        }
    }

    /**
     * Returns true if all of the composite filters return true;
     */
    private class ORCondition extends CompositeCondition {

        public ORCondition(Condition[] conditions) {
            super(conditions);
        }

        public Boolean isTrue(Object item) {
            for (Integer i = 0, j = conditions.size(); i < j; ++i) {
                if (conditions[i].isTrue(item)) return true;
            }

            return false;
        }
    }
}