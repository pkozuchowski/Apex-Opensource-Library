/**
* MIT License
*
* Copyright (c) 2021 Piotr Kożuchowski
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
 * Factory class for Collection.Filter implementations.
 */
public inherited sharing class CollectionFilters {

    /**
     * Creates filter which returns true if all of the filters return true
     */
    public static Collection.Filter ANDs(Collection.Filter f1, Collection.Filter f2) {
        return ANDs(f1, f2, null);
    }
    public static Collection.Filter ANDs(Collection.Filter f1, Collection.Filter f2, Collection.Filter f3) {
        return ANDs(f1, f2, f3, null);
    }
    public static Collection.Filter ANDs(Collection.Filter f1, Collection.Filter f2, Collection.Filter f3, Collection.Filter f4) {
        return ANDs(f1, f2, f3, f4, null);
    }
    public static Collection.Filter ANDs(Collection.Filter f1, Collection.Filter f2, Collection.Filter f3, Collection.Filter f4, Collection.Filter f5) {
        return new CollectionImpl.FilterAND(f1, f2, f3, f4, f5);
    }


    /**
     * Creates filter which returns true if any of the filters return true
     */
    public static Collection.Filter ORs(Collection.Filter f1, Collection.Filter f2) {
        return ORs(f1, f2, null);
    }
    public static Collection.Filter ORs(Collection.Filter f1, Collection.Filter f2, Collection.Filter f3) {
        return ORs(f1, f2, f3, null);
    }
    public static Collection.Filter ORs(Collection.Filter f1, Collection.Filter f2, Collection.Filter f3, Collection.Filter f4) {
        return ORs(f1, f2, f3, f4, null);
    }
    public static Collection.Filter ORs(Collection.Filter f1, Collection.Filter f2, Collection.Filter f3, Collection.Filter f4, Collection.Filter f5) {
        return new CollectionImpl.FilterOR(f1, f2, f3, f4, f5);
    }


    /**
     * Creates filter by field value
     */
    public static Collection.FieldFilterFactory field(String field) {
        return new CollectionImpl.FieldFilterFactoryImpl(field);
    }
    public static Collection.FieldFilterFactory field(SObjectField field) {
        return new CollectionImpl.FieldFilterFactoryImpl('' + field);
    }
}