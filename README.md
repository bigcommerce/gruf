# gruf - gRPC Ruby Framework

[![CircleCI](https://circleci.com/gh/bigcommerce/gruf/tree/main.svg?style=svg)](https://circleci.com/gh/bigcommerce/gruf/tree/main) [![Gem Version](https://badge.fury.io/rb/gruf.svg)](https://badge.fury.io/rb/gruf) [![Documentation](https://inch-ci.org/github/bigcommerce/gruf.svg?branch=main)](https://inch-ci.org/github/bigcommerce/gruf?branch=main) [![Maintainability](https://api.codeclimate.com/v1/badges/4a8e9269f99100aeb7cb/maintainability)](https://codeclimate.com/github/bigcommerce/gruf/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/4a8e9269f99100aeb7cb/test_coverage)](https://codeclimate.com/github/bigcommerce/gruf/test_coverage)

gruf is a Ruby framework that wraps the [gRPC Ruby library](https://github.com/grpc/grpc/tree/master/src/ruby) to
provide a more streamlined integration into Ruby and Ruby on Rails applications.

It provides an abstracted server and client for gRPC services, along with other tools to help get gRPC services in Ruby
up fast and efficiently at scale. Some of its features include:

* Abstracted controllers with request context support
* Full interceptors with timing and unified request context support
* Robust client error handling and metadata transport abilities
* Server authentication via interceptors, with basic auth with multiple key support built in
* TLS support for client-server auth, though we recommend using [linkerd](https://linkerd.io/) instead
* Error data serialization in output metadata to allow fine-grained error handling in the transport while
  still preserving gRPC BadStatus codes
* Server and client execution timings in responses

gruf currently has active support for gRPC 1.10.x+. gruf is compatible and tested with Ruby 2.6-3.1.
gruf is also not [Rails](https://github.com/rails/rails)-specific, and can be used in any Ruby framework
(such as [Grape](https://github.com/ruby-grape/grape) or [dry-rb](https://dry-rb.org/), for instance).

### Getting Started

Please see the [gruf wiki](https://github.com/bigcommerce/gruf/wiki) for detailed information on getting started
using gruf.

## Demo Rails App

There is a [demonstration Rails application here](https://github.com/bigcommerce/gruf-demo) you can
view and clone that shows how to integrate Gruf into an existing Rails application.

## License

Copyright (c) 2017-present, BigCommerce Pty. Ltd. All rights reserved

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
