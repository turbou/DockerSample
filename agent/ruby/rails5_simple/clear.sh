#!/bin/sh

rm -fr Rakefile app bin config config.ru db lib log package.json public/ storage/ tmp vendor/ .ruby-version .git .gitignore test
git checkout Gemfile
git checkout Gemfile.lock
git checkout README.md

exit 0

