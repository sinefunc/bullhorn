require 'rubygems'
require 'test/unit'
require 'contest'
require 'mocha'
require 'fakeweb'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'bullhorn'

class Test::Unit::TestCase
end