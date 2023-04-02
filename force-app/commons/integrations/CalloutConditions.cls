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


public with sharing class CalloutConditions extends Conditions {

    /**
     * Executes when System.CalloutException was thrown.
     */
    public Condition onException() {
        return onException(null);
    }

    /**
     * Executes when System.CalloutException was thrown with given exception message
     */
    public Condition onException(String messageToMatch) {
        return new ExceptionMatcher(messageToMatch);
    }

    /**
     * Executes when webservice returned 401 Unauthorized
     */
    public Condition onUnauthorized() {
        return onStatusCode(401);
    }

    /**
     * Executes when webservice timed out
     */
    public Condition onTimeout() {
        return ORs(
            onException('Read timed out'),
            onStatusCode(408),
            onStatusCode(504)
        );
    }

    /**
     * Executes when webservice returned 404 Not Found
     */
    public Condition onNotFound() {
        return onStatusCode(404);
    }

    /**
     * Executes when webservice returned any success code 2XXs
     */
    public Condition onSuccess() {
        return onStatusCodeInRange(200, 299);
    }

    /**
     * Executes handler when webservice returned any server error code (5 00 - 5 99)
     */
    public Condition onBadRequest() {
        return onStatusCode(400);
    }

    /**
     * Executes handler when webservice returned any error code (400 - 599)
     */
    public Condition onAnyErrorCode() {
        return onStatusCodeInRange(400, 599);
    }

    /**
     * Executes handler when webservice returned any client error code (400 - 499)
     */
    public Condition onClientError() {
        return onStatusCodeInRange(400, 499);
    }

    /**
     * Executes handler when webservice returned any server error code (5 00 - 5 99)
     */
    public Condition onServerError() {
        return onStatusCodeInRange(500, 599);
    }

    /**
     * Executes when HttpResponse is exactly given status code
     */
    public Condition onStatusCode(Integer statusCode) {
        return new StatusCodeMatcher(statusCode);
    }

    /**
     * Executes when HttpResponse's Status Code is in given range (inclusive)
     */
    public Condition onStatusCodeInRange(Integer minStatusCode, Integer maxStatusCode) {
        return new StatusCodeMatcher(minStatusCode, maxStatusCode);
    }

    /**
     * Executes handler every time.
     */
    public Condition always() {
        return new CountMatcher(9999);
    }

    /**
     * Executes only once
     */
    public Condition once() {
        return new CountMatcher(1);
    }

    /**
     * Executes handler if response body matches regexp
     */
    public Condition onRegexMatch(String regex) {
        return new RegexMatcher(regex);
    }

    /**
     * Executes handler if response body matches regexp
     */
    public Condition onContains(String subString) {
        return new SubstringMatcher(subSTring);
    }

    /**
     * Executes handler if response body strictly deserializes to given type.
     */
    public Condition onDeserializableTo(Type apexTypeToDeserializeTo) {
        return new JsonMatcher(apexTypeToDeserializeTo);
    }


    /**
     * Checks StatusCode
     */
    private class StatusCodeMatcher implements Condition {
        private Integer min, max;
        private Boolean isRange = false;

        public StatusCodeMatcher(Integer expectedStatusCode) {
            this.min = expectedStatusCode;
        }

        public StatusCodeMatcher(Integer minStatus, Integer maxStatus) {
            this.min = minStatus;
            this.max = maxStatus;
            this.isRange = true;
        }

        public Boolean isTrue(Object o) {
            Callout c = (Callout) o;
            Integer statusCode = c.getResponse()?.getStatusCode();
            return isRange ? (statusCode >= min && statusCode <= max)
                : statusCode == min;
        }
    }

    /**
     * Returns true for X times.
     */
    private class CountMatcher implements Condition {
        private Integer maxCount, current = 0;

        public CountMatcher(Integer maxCount) {
            this.maxCount = maxCount;
        }

        public Boolean isTrue(Object o) {
            return current++ < maxCount;
        }
    }

    /**
     * Matches Response body with regex
     */
    private class RegexMatcher implements Condition {
        private String regex;

        public RegexMatcher(String regex) {
            this.regex = regex;
        }

        public Boolean isTrue(Object o) {
            Callout c = (Callout) o;

            if (c.getResponse() != null) {
                return Pattern.matches(regex, c.getResponse().getBody());
            }
            return false;
        }
    }

    /**
     * Matches Response body that contains substring
     */
    private class SubstringMatcher implements Condition {
        private String substring;

        private SubstringMatcher(String substring) {
            this.substring = substring;
        }

        public Boolean isTrue(Object item) {
            Callout c = (Callout) item;

            return c.getResponse()?.getBody()?.containsIgnoreCase(substring) == true;
        }
    }

    /**
     * Matches callout that had send exception
     */
    private class ExceptionMatcher implements Condition {
        private String messageToMatch;

        private ExceptionMatcher(String messageToMatch) {
            this.messageToMatch = messageToMatch;
        }

        public Boolean isTrue(Object item) {
            Callout c = (Callout) item;

            if (String.isBlank(messageToMatch)) {
                return c.getCalloutException() != null;
            } else {
                return c.getCalloutException()?.getMessage() == messageToMatch;
            }
        }
    }

    /**
     * Matches response that can be strictly deserialized to given type;
     */
    private class JsonMatcher implements Condition {
        private Type typeToMatch;

        private JsonMatcher(Type typeToMatch) {
            this.typeToMatch = typeToMatch;
        }

        public Boolean isTrue(Object item) {
            Callout c = (Callout) item;
            String body = c.getResponse()?.getBody();

            if (String.isNotBlank(body)) {
                try {
                    Object o = JSON.deserializeStrict(body, typeToMatch);
                    return true;

                } catch (JSONException e) {
                    return false;
                }
            }

            return false;
        }
    }
}