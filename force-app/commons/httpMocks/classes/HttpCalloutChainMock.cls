/**
* SPDX-License-Identifier: MIT
* Copyright 2018 Piotr Kożuchowski
* apexlibra.org
*/

/**
 * Variant of HttpCalloutMock implementing Chain of Responsibility pattern,
 * that first checks whether it can/should handle the callout.
 */
public interface HttpCalloutChainMock extends HttpCalloutMock {

    /**
     * This method checks if incoming request should be handled by this mock class.
     */
    Boolean handles(HttpRequest request);
}