/**
* MIT License
*
* Copyright (c) 2025 Piotr Kożuchowski
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
@SuppressWarnings('PMD.DuplicateMethods')
public virtual inherited sharing class QueryIssuer {
    private static final Map<String, Object> NO_BINDS = new Map<String, Object>();

    public virtual List<SObject> query(String query, Map<String, Object> binds, AccessLevel level) {
        return Database.queryWithBinds(query, binds ?? NO_BINDS, level);
    }

    public virtual Database.QueryLocator getQueryLocator(String query, Map<String, Object> binds, AccessLevel level) {
        return Database.getQueryLocatorWithBinds(query, binds ?? NO_BINDS, level);
    }

    public virtual Database.Cursor getCursor(String query, Map<String, Object> binds, AccessLevel level) {
        return Database.getCursorWithBinds(query, binds ?? NO_BINDS, level);
    }


    public with sharing class WithSharingIssuer extends QueryIssuer {
        public override List<SObject> query(String query, Map<String, Object> binds, AccessLevel level) {
            return super.query(query, binds, level);
        }

        public override Database.QueryLocator getQueryLocator(String query, Map<String, Object> binds, AccessLevel level) {
            return super.getQueryLocator(query, binds, level);
        }

        public override Database.Cursor getCursor(String query, Map<String, Object> binds, AccessLevel level) {
            return super.getCursor(query, binds, level);
        }
    }


    public without sharing class WithoutSharingIssuer extends QueryIssuer {
        public override List<SObject> query(String query, Map<String, Object> binds, AccessLevel level) {
            return super.query(query, binds, level);
        }

        public override Database.QueryLocator getQueryLocator(String query, Map<String, Object> binds, AccessLevel level) {
            return super.getQueryLocator(query, binds, level);
        }

        public override Database.Cursor getCursor(String query, Map<String, Object> binds, AccessLevel level) {
            return super.getCursor(query, binds, level);
        }
    }
}