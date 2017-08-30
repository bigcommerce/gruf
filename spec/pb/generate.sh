#!/bin/bash

set -e

grpc_tools_ruby_protoc --ruby_out=./ --grpc_out=./ ./rpc/ThingService.proto
