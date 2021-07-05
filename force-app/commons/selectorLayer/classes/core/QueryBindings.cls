/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2021 Piotr Kożuchowski
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
 *  Please find newest source code at https://github.com/amorek/Apex-Opensource-Library
 * /
 */

/**
 * This class represents dynamic bindings in the query string and generates unique name for each variable to prevent duplicates.
 */
public with sharing class QueryBindings {
    private Map<String, Object> bindings = new Map<String, Object>();
    private Integer counter = 0;

    /**
     * @param value Query value to register that will be bound to SOQL query
     * @return Unique name that should be used in SOQL.
     */
    public String registerBinding(Object value) {
        String name = ':var' + counter++;
        this.bindings.put(name, value);

        return name;
    }

    public Map<String, Object> getMap() {
        return bindings;
    }

    /**
     * Registers bindings and replaces binding names in SOQL string to unique values.
     */
    public String replaceReferences(String soql, Map<String, Object> params) {
        String newSOQL = soql;

        for (String paramName : params.keySet()) {
            Object paramValue = params.get(paramName);

            String uniqueName = registerBinding(paramValue);
            newSOQL = replaceReferences(newSOQL, paramName, uniqueName);
        }

        return newSOQL;
    }

    /**
     * Replaces bindings from old to new name in SOQL string
     */
    public String replaceReferences(String soql, String oldVariable, String newVariable) {
        return soql.replaceAll(':\\s*' + oldVariable, newVariable);
    }
}