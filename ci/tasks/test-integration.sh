#!/usr/bin/env bash

set -e

source bosh-src/ci/tasks/utils.sh

check_param RUBY_VERSION
check_param DB

echo "Starting $DB..."
case "$DB" in
  mysql)
    sudo service mysql start
    ;;
  postgresql)
    export PATH=/usr/lib/postgresql/9.4/bin:$PATH
    #adduser --disabled-password --gecos "" postgres
    su postgres -c '
      export PATH=/usr/lib/postgresql/9.4/bin:$PATH
      export PGDATA=/tmp/postgres
      export PGLOGS=/tmp/log/postgres
      mkdir -p $PGDATA
      mkdir -p $PGLOGS
      initdb -U postgres -D $PGDATA
      pg_ctl start -l $PGLOGS/server.log -o "-N 400"
    '
    ;;
  *)
    echo $"Usage: DB={mysql|postgresql} $0 {commands}"
    exit 1
esac

source /etc/profile.d/chruby.sh
chruby $RUBY_VERSION

cd bosh-src

print_git_state

bundle install --local
export GOPATH=$(pwd)/go
export GOBIN=$(pwd)/go/gobin
export PATH=/usr/local/ruby/bin:/usr/local/go/bin:$GOBIN:$PATH
export BOSH_CLI_SILENCE_SLOW_LOAD_WARNING=true

# For running all integration specs
bundle exec rake --trace spec:integration

## For running individual specs
#bundle exec rake spec:integration:install_dependencies
#bundle exec rspec spec/integration/FILENAME:LINE_NUMBER
