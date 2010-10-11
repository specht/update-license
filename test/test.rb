require 'test/unit'
require 'yaml'
require 'update-license.rb'

class StringTest < Test::Unit::TestCase
#     def setup
#     end

#     def teardown
#     end

    def testParser
        Dir['test/extraction/*'].each do |path|
            puts path
            query = File::read(path)
            response = query.index('[|]')
            query.sub!('[|]', '')
            puts response
#             assert_equal(x[:result], result)
        end
    end
end
