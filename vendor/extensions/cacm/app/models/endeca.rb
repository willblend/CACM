#ENV['JAVA_HOME'] = '/usr/lib/jvm/java-6-sun-1.6.0.07' unless ENV['JAVA_HOME']
ENV['JAVA_HOME'] = '/usr/lib/jvm/java-6-sun'
require 'java'
require 'rjb'

# do not set this below 2m as allocating lower memory to this can lead to strange
# site behavior like serving empty pages. (old default that led to problems = 256k)
Rjb::load File.join(CacmExtension.root, %w(lib endeca_navigation.jar)), ['-Xss2m']

jrequire 'com.endeca.navigation.ENEQuery'
jrequire 'com.endeca.navigation.ERecSearch'
jrequire 'com.endeca.navigation.ERecSearchList'
jrequire 'com.endeca.navigation.DimValIdList'
jrequire 'com.endeca.navigation.HttpENEConnection'
jrequire 'com.endeca.navigation.FieldList'

module Endeca
end
