# Seevibes Connectors

These are the Seevibes Connectors, a collection of libraries that ease our burden when connecting to external services.

# Usage

```
git clone git@github.com:seevibes/svconnectors.git
cd svconnectors
bundle install
bundle exec rspec
```

# Architecture

## The Seevibes Protocol

Since Ruby does not have the concept of an interface, we have to fake this. The best way we have is to write some tests
that will guide you. Of course, the tests will be insufficient, since the tests can only indicate the presence of required
methods. Your job will be to implement the methods that the Seevibes Protocol expects.

### Connecting Connectors

When the Seevibes Platform receives a request to connect a connector, we start by going through the OAuth flow. When the
OmniAuth callback fires (in the Seevibes Platform code), your code will start to execute. The methods you have to implement
are:

1. Class-level `.call(omniauth_params, omniauth_auth)`: instead of calling `#new`, we prefer to `#call` into your code.
    This allows you to return a subclass, if that is required for the connector.

2. `#description`:         Returns a plain-text description of the connection. The text won't be localized.
                           Returning the account's name is a perfectly valid option, as well as the empty string.
                           Must not return nil; the empty string is an acceptable return value.

3. `#account_identifiers`: Returns a Ruby Hash that describes the account to which this instance is connected.
                           This exact Hash (after serialization to JSON) will be provided to the Dispatcher.
                           Must not return nil; the empty hash is an acceptable return value.

4. `#credential_details`:  Returns a Ruby Hash with all the information needed to make API calls later.
                           This exact Hash (after serialization to JSON) will be provided to the Dispatcher.
                           Must not return nil; the empty hash is an acceptable return value.


## Reference Implementations

Please see the implementations of the Mailchimp, Shopify and Hubspot connectors for inspiration.

# License

The code in this library is Copyright 2016, Technologies Seevibes Inc.
