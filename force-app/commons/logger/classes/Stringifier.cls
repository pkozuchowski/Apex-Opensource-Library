/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2022 Piotr Kożuchowski
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
 * Formats objects into org-uniform String representation
 */
public with sharing class Stringifier {

    /**
    * @return String representation of exception
    * <pre>
    *     System.NullPointerException: Script-thrown exception
    *     Stack: line X, column Y
    *
    *     Caused By:
    *     ExceptionType: Exception Message
    *     CauseStack: line X, column Y
    * </pre>
    */
    public static String toString(Exception ex) {
        if (ex == null) {
            return '';

        } else {
            List<String> lines = new List<String>{
                ex.getTypeName() + ': ' + ex.getMessage(),
                ex.getStackTraceString().substringBefore('Caused by')
            };
            if (ex.getCause() != null) {
                lines.add('Caused by');
                lines.add(toString(ex.getCause()));
            }

            return join(lines);
        }
    }


    /**
    * @return String representation of HttpRequest derived from Http method, endpoint and body
    * <pre>
    *     POST /services/data/v20.0/sobjects/Account/
    *     Host: yourInstance.salesforce.com
    *     Content-Type:application/json
    *
    *     {"Name":"Test Account}
    * </pre>
    */
    public static String toString(HttpRequest request) {
        return toString(request, new List<String>{'Content-Type', 'Accept'});
    }

    public static String toString(HttpRequest request, List<String> headerKeys) {
        if (request == null) {
            return '';

        } else {
            Url url = new Url(request.getEndpoint());
            List<String> lines = new List<String>{
                request.getMethod() + ' ' + url.getFile(),
                'Host: ' + url.getHost()
            };

            for (String headerKey : headerKeys) {
                String headerValue = request.getHeader(headerKey);

                if (String.isNotEmpty(headerValue)) {
                    lines.add(headerKey + ': ' + request.getHeader(headerKey));
                }
            }

            lines.add('');
            lines.add(request.getBody());

            return join(lines);
        }
    }

    /**
    * @return String representation of HttpResponse derived from Http status, code and body
    * <pre>
    *     200 OK
    *     Content-Type: application/json
    *
    *     {
    *       "orderNumber":"Test"
    *     }
    * </pre>
    */
    public static String toString(HttpResponse response) {
        if (response == null) {
            return '';

        } else {
            List<String> lines = new List<String>{
                response.getStatusCode() + ' ' + response.getStatus()
            };

            for (String headerKey : response.getHeaderKeys()) {
                String headerValue = response.getHeader(headerKey);

                if (String.isNotEmpty(headerValue)) {
                    lines.add(headerKey + ': ' + response.getHeader(headerKey));
                }
            }

            lines.add('');
            lines.add(response.getBody());

            return join(lines);
        }
    }

    /**
    * @return String representation of RestRequest derived from Http method, endpoint, query params and body
    * <pre>
    *     POST /services/data/v20.0/sobjects/Account/
    *     Host: yourInstance.salesforce.com
    *     Authorization:Bearer XXX
    *     Content-Type:application/json
    *
    *     URL Parameters:
    *     id: 001000000000000
    *
    *     {"Name":"Test Account}
    * </pre>
    */
    public static String toString(RestRequest request) {
        if (request == null) {
            return '';

        } else {
            List<String> lines = new List<String>{
                request.httpMethod + ' ' + request.resourcePath
            };

            String paramSeparator = '?';
            for (String param : request.params.keySet()) {
                lines.add('\t' + paramSeparator + param + '=' + request.params.get (param));

                if (paramSeparator == '?') {
                    paramSeparator = '&';
                }
            }

            lines.add('Host: ' + Url.getOrgDomainUrl().getHost());
            lines.add(toString(request.headers));
            lines.add('');
            lines.add(toString(request.requestBody));
            return join(lines);
        }
    }

    /**
    * @return String representation of RestResponse derived from response status code, headers and body
    * <pre>
    *     POST http://salesforce.instance.com/apexrest/orders
    *     market : US
    *     brand: ACME
    *
    *     {
    *       "orderNumber":"Test"
    *     }
    * </pre>
    */
    public static String toString(RestResponse response) {
        if (response == null) {
            return '';

        } else {
            return join(new List<String>{
                '' + response.statusCode,
                toString(response.headers),
                '',
                toString(response.responseBody)
            });
        }
    }

    /**
    * @return String representation of a Map
    * <pre>
    *     Key1: Value1
    *     Key2: Value2
    * </pre>
    */
    public static String toString(Map<String, Object> mapInstance) {
        if (mapInstance == null) {
            return '';

        } else {
            List<String> values = new List<String>();
            for (String key : mapInstance.keySet()) {
                values.add(key + ': ' + mapInstance.get(key));
            }
            return join(values);
        }
    }

    /**
    * @return String representation of a Blob. If possible, returns blob.toString(),
    * for non UTF-8 generic string Blob[12] is returned where 12 is size of blob.
    */
    public static String toString(Blob b) {
        if (b == null) {
            return '';
        } else {
            try {
                return b.toString();
            } catch (Exception ex) {
                return '' + b;
            }
        }
    }

    private static String join(List<String> lines) {
        return String.join(lines, '\n').trim();
    }

    private Stringifier() {}
}