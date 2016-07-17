#!/usr/bin/env bash

set -e

export RUBY_VERSION=2.3.1


source bosh-src/ci/tasks/utils.sh
check_param RUBY_VERSION

echo "Starting $DB..."
case "$DB" in
  mysql)
    mv /var/lib/mysql /var/lib/mysql-src
    mkdir /var/lib/mysql
    mount -t tmpfs -o size=256M tmpfs /var/lib/mysql
    mv /var/lib/mysql-src/* /var/lib/mysql/

    sudo service mysql start
    ;;
  postgresql)
    export PATH=/usr/lib/postgresql/9.4/bin:$PATH

    mkdir /tmp/postgres
    mount -t tmpfs -o size=256M tmpfs /tmp/postgres
    mkdir /tmp/postgres/data
    chown postgres:postgres /tmp/postgres/data

    su postgres -c '
      export PATH=/usr/lib/postgresql/9.4/bin:$PATH
      export PGDATA=/tmp/postgres/data
      export PGLOGS=/tmp/log/postgres
      mkdir -p $PGDATA
      mkdir -p $PGLOGS
      initdb -U postgres -D $PGDATA
      pg_ctl start -w -l $PGLOGS/server.log -o "-N 400"
    '
    ;;
  sqlite)
    echo "Using sqlite"
    ;;
  *)
    echo "Usage: DB={mysql|postgresql|sqlite} $0 {commands}"
    exit 1
esac

source /etc/profile.d/chruby.sh
chruby $RUBY_VERSION

cd bosh-src
print_git_state

export GOPATH=$(pwd)/go
export GOBIN=$(pwd)/go/gobin
export PATH=/usr/local/ruby/bin:/usr/local/go/bin:$GOBIN:$PATH
#export GOROOT=/usr/local/go
export TRAVIS=true
bundle install --local
bundle exec rake --trace spec:unit:ruby
