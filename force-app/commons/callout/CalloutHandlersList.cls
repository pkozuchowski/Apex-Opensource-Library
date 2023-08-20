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

/**
 * List of handlers that can be modified and then execute during callout.
 * @see CalloutTest for an examples.
 */
public with sharing class CalloutHandlersList {
    private List<MatcherHandler> matcherHandlers = new List<MatcherHandler>();
    private List<MatcherHandler> lockedHandlers;

    /**
     * Adds Callout Handler that will execute if Matcher returns true
     */
    public CalloutHandlersList add(Condition matcher, Callout.Handler handler) {
        return add('', matcher, handler);
    }

    /**
     * Adds Named Callout Handler that will execute if Matcher returns true.
     * Named handlers can be removed or replaced.
     */
    public CalloutHandlersList add(String name, Condition matcher, Callout.Handler handler) {
        matcherHandlers.add(new MatcherHandler(name, matcher, handler));
        return this;
    }

    /**
     * Adds Handler in specified slot. Many Handlers can go into one slot.
     */
    public CalloutHandlersList addToSlot(String slotName, Condition matcher, Callout.Handler handler) {
        MatcherHandler matcherHandler = new MatcherHandler('', matcher, handler);

        for (Integer i = 0; i < matcherHandlers.size(); i++) {
            if (matcherHandlers[i].name == slotName) {
                matcherHandlers.add(i, matcherHandler);
                break;
            }
        }

        return this;
    }

    /**
     * Removes handler with given name
     */
    public CalloutHandlersList remove(String name) {
        if (String.isNotBlank(name)) {
            for (Integer i = 0; i < matcherHandlers.size(); i++) {
                if (matcherHandlers[i].name == name) {
                    matcherHandlers.remove(i);
                    break;
                }
            }
        }

        return this;
    }

    /**
     * Creates a slot in handler's list that can be filled at later term.
     * Example use-case is when we have API specific callout class where most of the handlers reside, but for specific
     * request, we need to inject a handler in the middle of the list.
     * @See CalloutTest.AcmeAPI.getAccount for an example.
     */
    public CalloutHandlersList slot(String slotName) {
        this.matcherHandlers.add(new MatcherHandler(slotName));
        return this;
    }


    /**
     * Replaces named handler with different one, while condition remains unchanged.
     */
    public CalloutHandlersList replace(String name, Callout.Handler handler) {
        for (MatcherHandler matcherHandler : matcherHandlers) {
            if (matcherHandler.name == name) {
                matcherHandler.handler = handler;
            }
        }
        return this;
    }

    /**
     * Clears list of handlers
     */
    public CalloutHandlersList clear() {
        matcherHandlers.clear();
        return this;
    }

    /**
     * Executes handlers on callout.
     * This should never be called by user, Callout class does this.
     */
    public Object execute(Callout c) {
        if (lockedHandlers == null) {
            lockedHandlers = new List<MatcherHandler>(matcherHandlers);
        }

        for (MatcherHandler handler : lockedHandlers) {
            Boolean matches = handler.isTrue(c);

            if (matches) {
                Object handlerResponse = handler.handle(c);

                if (handlerResponse != null) {
                    return handlerResponse;
                }
            }
        }

        return null;
    }


    private virtual class MatcherHandler implements Condition, Callout.Handler {
        private Condition matcher;
        private Callout.Handler handler;
        private String name;
        private Boolean isSlot;

        private MatcherHandler(String slotName) {
            this.isSlot = true;
            this.name = slotName;
        }

        private MatcherHandler(String name, Condition matcher, Callout.Handler handler) {
            this.matcher = matcher;
            this.handler = handler;
            this.name = name;
        }

        public Boolean isTrue(Object c) {
            return matcher?.isTrue(c) == true;
        }

        public Object handle(Callout c) {
            return handler?.handle(c);
        }
    }
}