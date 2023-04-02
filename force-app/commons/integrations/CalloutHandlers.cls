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
 */


public virtual with sharing class CalloutHandlers {

    /**
     * Executes callout again for specified number of times, as long as Matcher's condition is fulfilled.
     */
    public Callout.Handler retry(Integer i) {
        return new RetryHandler(i);
    }

    /**
     * Throws default Callout Exception with Http Response
     */
    public Callout.Handler throwEx() {
        return throwEx(null);
    }

    /**
     * Throws default Callout Exception with Http Response
     */
    public Callout.Handler throwEx(String message) {
        return new ExceptionHandler(new CalloutResponseException(message));
    }

    /**
     * Deserializes response to given apex type and attaches it to callout exception
     */
    public Callout.Handler throwResponseEx(Type errorType) {
        return new ExceptionHandler(errorType);
    }


    /**
     * Callout execute will return given value
     */
    public Callout.Handler returns(Object returnValues) {
        return new ReturnHandler(returnValues);
    }

    /**
     * Callout will deserialize response to given type and return as result from execute method.
     */
    public Callout.Handler returnJSON(Type apexType) {
        return new JsonHandler(apexType);
    }

    /**
     * Logs Callout with given level.
     */
    public Callout.Handler logCallout(LoggingLevel level) {
        return new LogHandler(level);
    }

    /**
     * Replaces all occurrences of substring with substitution
     */
    public Callout.Handler replaceAll(String regex, String substitution) {
        return new SubstringHandler(regex, substitution);
    }


    /**
     * Executes the callout again and again until set amount of retries is reached.
     */
    private class RetryHandler implements Callout.Handler {
        private Integer attempt = 0, maxAttempts;

        public RetryHandler(Integer howManyTimes) {
            maxAttempts = howManyTimes;
        }

        public Object handle(Callout c) {
            if (attempt < maxAttempts) {
                attempt++;
                return c.execute();
            }

            return null;
        }
    }

    /**
     * Throw defined exception on given callouts condition
     */
    private class ExceptionHandler implements Callout.Handler {
        private CalloutResponseException ex;
        private Type errorResponseType;

        public ExceptionHandler(CalloutResponseException ex) {
            this.ex = ex;
        }

        public ExceptionHandler(Type errorResponseType) {
            this.errorResponseType = errorResponseType;
        }

        public Object handle(Callout c) {
            HttpResponse httpResponse = c.getResponse();
            String body = httpResponse?.getBody();
            if (String.isNotBlank(body) && errorResponseType != null) {
                ex = (CalloutResponseException) JSON.deserialize(body, errorResponseType);
            }

            if (String.isEmpty(ex.getMessage())) {
                ex.setMessage(httpResponse?.getStatusCode() + ' ' + httpResponse?.getStatus());
            }

            ex.setHttpResponse(httpResponse);
            throw ex;
        }
    }

    /**
     * Returns set value on given callouts condition
     */
    private class ReturnHandler implements Callout.Handler {
        private Object value;

        public ReturnHandler(Object value) {
            this.value = value;
        }

        public Object handle(Callout c) {
            return value;
        }
    }

    /**
     * Returns JSON from response
     */
    private class JsonHandler implements Callout.Handler {
        private Type resultType;

        public JsonHandler(Type resultType) {
            this.resultType = resultType;
        }

        public Object handle(Callout callout) {
            return resultType == null ? null
                : JSON.deserialize(callout.getResponse().getBody(), resultType);
        }
    }

    /**
     * Logs callout details in database using platform event
     */
    private class LogHandler implements Callout.Handler {
        private LoggingLevel level;

        public LogHandler(LoggingLevel level) {
            this.level = level;
        }

        public Object handle(Callout c) {
            Logger.log(level, new Log(c.getRequest(), c.getResponse())
                .withApexClass(c.getLogName()));
            return null;
        }
    }

    /**
     * Replaces substring on response body
     */
    private class SubstringHandler implements Callout.Handler {
        private String substitution, regex;

        public SubstringHandler(String regex, String substitution) {
            this.regex = regex;
            this.substitution = substitution;
        }

        public Object handle(Callout c) {
            HttpResponse httpResponse = c.getResponse();
            String body = httpResponse?.getBody();

            if (httpResponse != null && String.isNotBlank(body)) {
                String newBody = body.replaceAll(regex, substitution);
                httpResponse.setBody(newBody);
            }

            return null;
        }
    }

}