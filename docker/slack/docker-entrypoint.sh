#!/bin/sh

set -eu

bundle exec rackup bin/slack_bot_server.ru
