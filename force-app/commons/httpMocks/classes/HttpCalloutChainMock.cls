/**
* SPDX-License-Identifier: MIT
* Copyright 2018 Piotr Kożuchowski
* apexlibra.org
*/
public interface HttpCalloutChainMock extends HttpCalloutMock {

    /**
     * This method checks if incoming request should be handled by this mock class.
     */
    Boolean handles(HttpRequest request);
}