/**
* MIT License
*
* Copyright (c) 2020 Piotr Kożuchowski
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
 * Implement this interface to mock selector query results in unit tests
 */
public interface SelectorQueryMock {


    /**
     * When mock is set for selector, this method will be called to determine the query result.
     * Mock is supplied with information about caller class of selector, called selector and method, query bound variables and original result.
     *
     * @param caller    Name of class which called the selector (ex. 'AccountLogic')
     * @param callerMethod  Caller's method in which selector was called
     * @param selector  Name of selector class (ex. 'AccountSelector')
     * @param selectorMethod Name of called method of selector (ex. 'byName')
     * @param queryBoundVariables Variables bound to the query
     * @param queryResult Real result of the executed query
     *
     * @return Mocked query result
     */
    SObject[] handleQuery(
            String caller,
            String callerMethod,
            String selector,
            String selectorMethod,
            Map<String, Object> queryBoundVariables,
            SObject[] queryResult
    );
}