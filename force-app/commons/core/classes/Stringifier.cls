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
    public String toString(Exception ex) {
        if (ex == null) {
            return '';

        } else {
            return ex.getTypeName() + ': ' + ex.getMessage()
                    + '\n' + ex.getStackTraceString().substringBefore('Caused by')
                    + (ex.getCause() == null ? '' : '\nCaused by\n' + toString(ex.getCause()));
        }
    }


    /**
    * @return String representation of HttpRequest derived from Http method, endpoint and body
    * <pre>
    *     POST /services/data/v20.0/sobjects/Account/
    *     Host: yourInstance.salesforce.com
    *     Authorization:Bearer XXX
    *     Content-Type:application/json
    *
    *     {"Name":"Test Account}
    * </pre>
    */
    public String toString(HttpRequest request) {
        return toString(request, new List<String>{'Authorization', 'Content-Type'});
    }

    public String toString(HttpRequest request, List<String> headerKeys) {
        if (request == null) {
            return '';

        } else {
            Url url = new Url(request.getEndpoint());
            String result = request.getMethod() + ' ' + url.getFile() + '\n'
                    + 'Host: ' + url.getHost() + '\n';

            List<String> headers = new List<String>();
            for (String headerKey : headerKeys) {
                String headerValue = request.getHeader(headerKey);

                if (String.isNotEmpty(headerValue)) {
                    headers.add(headerKey + ': ' + request.getHeader(headerKey));
                }
            }

            result += String.join(headers, '\n');
            result += '\n\n' + request.getBody();

            return result;
        }
    }

    /**
    * @return String representation of HttpResponse derived from Http status, code and body
    * <pre>
    *     200 OK
    *
    *     {
    *       "orderNumber":"Test"
    *     }
    * </pre>
    */
    public String toString(HttpResponse response) {
        if (response == null) {
            return '';

        } else {
            return response.getStatusCode() + ' ' + response.getStatus()
                    + '\n\n' + response.getBody();
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
    public String toString(RestRequest request) {
        if (request == null) {
            return '';

        } else {
            return request.httpMethod + ' ' + request.resourcePath + '\n'
                    + 'Host: ' + Url.getOrgDomainUrl().getHost() + '\n'
                    + toString(request.headers) + '\n'
                    + '\nURL Parameters:\n'
                    + toString(request.params)
                    + '\n\n'
                    + toString(request.requestBody);
        }
    }

    /**
    * @return String representation of RestResponse derived from response status code, headers and body
    * <pre>
    *     POST http://salesforce.instance.com/apexrest/orders
    *     Params:
    *     market : US
    *     brand: ACME
    *
    *     Body:
    *     {
    *       "orderNumber":"Test"
    *     }
    * </pre>
    */
    public String toString(RestResponse response) {
        if (response == null) {
            return '';

        } else {
            String headers = toString(response.headers);

            return response.statusCode + '\n'
                    + (String.isEmpty(headers) ? '' : headers + '\n')
                    + '\n' + toString(response.responseBody);
        }
    }

    /**
    * @return String representation of a Map
    * <pre>
    *     Key1: Value1
    *     Key2: Value2
    * </pre>
    */
    public String toString(Map<String, String> mapInstance) {
        if (mapInstance == null) {
            return '';

        } else {
            List<String> values = new List<String>();
            for (String key : mapInstance.keySet()) {
                values.add(key + ': ' + mapInstance.get(key));
            }
            return String.join(values, '\n');
        }
    }

    /**
    * @return String representation of a Blob. If possible, returns blob.toString(),
    * for non UTF-8 generic string Blob[12] is returned where 12 is size of blob.
    */
    public String toString(Blob b) {
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
}