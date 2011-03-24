set :domain, '192.168.0.161'
default_environment['LD_LIBRARY_PATH'] = '/opt/local/oracle-instant-client'
default_environment['JAVA_HOME'] = '/usr/lib/jvm/java-1.6.0-sun-1.6.0.10'
set :repository,  "josh.local:~/cacm"
set :scm, 'git'
set :branch, 'master'
set :deploy_via, :checkout