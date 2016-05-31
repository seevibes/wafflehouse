# Connectors Documentation

## Presentation

The role of the Connectors is to enable Seevibes to gather the list of mailing lists available on different "connectors". Mailchimp, Hubspot and Shopify are different connectors.

## Your Role

Your role will consist in the following steps:

1. Find and or implement an [omniauth](https://github.com/intridea/omniauth/wiki) backend;
2. Implement the [Seevibes Connector Protocol](#the-seevibes-connector-protocol) in a class;
3. Implement the [Seevibes Dispatcher Protocol](#the-seevibes-dispatcher-protocol) in a second class;
4. Implement the [Seevibes Downloader Protocol](#the-seevibes-downloader-protocol) in a third class;
5. Do manual and automated testing of the written code; [rspec](http://rspec.info/) is our tool of choice.


# Architecture

Since Ruby does not have the concept of an interface, we have to fake this. The best way we have is to write some tests
that will guide you. Of course, the tests will be insufficient, since the tests can only indicate the presence of required
methods. Your job will be to implement the methods that the Seevibes Protocol expects.


## Protocols


### The Seevibes Connector Protocol

When the Seevibes Platform receives a request to connect a connector, we start by going through the OAuth flow. When the
OmniAuth callback fires (in the Seevibes Platform code), your code will start to execute. The methods you have to implement
are:

1. Class-level `.call(omniauth_params:, omniauth_auth:)`:
    Instead of calling `#new`, we prefer to `#call` into your code.
    This allows you to return a subclass, if that is required for the connector.

2. `#description`:
    Returns a plain-text description of the connection. The text won't be localized.
    Returning the account's name is a perfectly valid option, as well as the empty string.
    Must not return nil; the empty string is an acceptable return value.

3. `#account_identifiers`:
    Returns a Ruby Hash that describes the account to which this instance is connected.
    This exact Hash (after serialization to JSON) will be provided to the Dispatcher.
    Must not return nil; the empty hash is an acceptable return value.

4. `#credential_details`:
    Returns a Ruby Hash with all the information needed to make API calls later.
    This exact Hash (after serialization to JSON) will be provided to the Dispatcher.
    Must not return nil; the empty hash is an acceptable return value.


## The Seevibes Dispatcher Protocol

Instances of the Dispatcher Protocol are responsible for handling retries and rate limits with regards to remote
APIs. The required protocol interface is:

1. Class-level `.call(account_identifiers:, credential_details:)`:
    Instead of calling `#new`, we prefer to `#call` into your code.
    This allows you to return a subclass, if that is required for the connector.

2. `#dispatch(method, path)`
    This is the sole required method in the Dispatcher protocol. It's purpose is to handle the retry and rate limit
    logic, and shield the downloaders from those details.


## The Seevibes Downloader Protocol

Instances of the Downloader Protocol are responsible for enumerating mailing lists and emails in a list. The required
protocol interface is:

1. Class-level `.call(account_identifiers:, credential_details:)`:
    Instead of calling `#new`, we prefer to `#call` into your code.
    This allows you to return a subclass, if that is required for the connector.

2. `#each_list(&block)`:
    This method is responsible for yielding each mailing list or customer list using a Ruby Hash with the following
    structure: `{name: String, id: Object, size: Fixnum}`.

3. `#each_email(id:, &block)`:
    This method is responsible for yielding each email address from the specified list. We expect to receive only
    the email address, and no other details.


## Reference Implementations

Please see the implementations of the Mailchimp, Shopify and Hubspot connectors for inspiration.
