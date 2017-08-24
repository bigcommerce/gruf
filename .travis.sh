#!/bin/bash
set -e

if [ "$TEST_GROUP" == "prereq" ]
then
  bundle exec bundle-audit update
  bundle exec bundle-audit check -v
  bundle exec rubocop -P

elif [ "$TEST_GROUP"  == "1" ]
then
  bundle exec rspec
fi


