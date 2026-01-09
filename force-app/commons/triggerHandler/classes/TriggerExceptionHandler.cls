// SPDX-License-Identifier: MIT
// Copyright 2025 Piotr Kożuchowski

/**
 * Interface for handling exceptions that occur during trigger processing.
 * Implement this interface to define custom behavior when exceptions are thrown
 * in trigger handlers.
 *
 * Framework will query all implementations of this interface and invoke the
 * onException method when an exception occurs.
 */
public interface TriggerExceptionHandler {
    void onException(Exception ex, TriggerContext ctx);
}