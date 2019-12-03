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
public with sharing class Formatter {

    public String format(Exception ex) {
        if (ex != null) {
            return ex.getTypeName() + ': ' + ex.getMessage()
                    + '\n' + ex.getStackTraceString().substringBefore('Caused by')
                    + (ex.getCause() != null ? '\nCaused by\n' + format(ex.getCause()) : '');

        } else {
            return '';
        }
    }

    public String format(HttpRequest request) {
        if (request != null) {
            return request.getMethod() + ' ' + request.getEndpoint() + '\n'
                    + request.getBody();
        } else {
            return '';
        }
    }

    public String format(HttpResponse response) {
        if (response != null) {
            return 'Response:\n'
                    + response.getStatusCode() + ' ' + response.getStatus()
                    + '\n' + response.getBody();
        } else {
            return '';
        }
    }

    public String format(RestRequest request) {
        if (request != null) {
            String params = format(request.params);
            String body = format(request.requestBody);

            return request.httpMethod + ' ' + request.resourcePath
                    + (String.isEmpty(params) ? '' : '\nParams:\n' + params)
                    + (String.isEmpty(body) ? '' : '\nBody:\n' + body);
        } else {
            return '';
        }
    }

    public String format(RestResponse response) {
        if (response != null) {
            String body = format(response.responseBody);
            String headers = format(response.headers);

            return 'Response:\n'
                    + response.statusCode
                    + (String.isEmpty(headers) ? '' : +'\nHeaders:\n' + headers)
                    + (String.isEmpty(body) ? '' : '\nBody:\n' + body);
        } else {
            return '';
        }
    }

    public String format(Map<String, String> mapInstance) {
        List<String> values = new List<String>();
        for (String key : mapInstance.keySet()) {
            values.add('"' + key + '" : "' + mapInstance.get(key) + '"');
        }
        return String.join(values, '\n');
    }

    public String format(Blob b) {
        try {
            return b.toString();
        } catch (Exception ex) {
            return b.size() == 0 ? '' : '' + b;
        }
    }
}