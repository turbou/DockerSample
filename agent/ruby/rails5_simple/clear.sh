#!/bin/sh

rm -fr Rakefile app bin config config.ru db lib log package.json public/ storage/ tmp vendor/ .ruby-version .git .gitignore test README.md
git checkout Gemfile
git checkout Gemfile.lock

exit 0

