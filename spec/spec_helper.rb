require 'rubygems'
require 'bundler/setup'
Bundler.setup

require 'obo_parser'
require 'pry'
require 'awesome_print'
require 'fileutils'

# FileUtils::mkdir_p 'tmp'

RSpec.configure do |config|

  config.raise_errors_for_deprecations!

   config.run_all_when_everything_filtered = false 
   # config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  # config.order = 'random'

end

# def in_range(value, percentage, midpoint)  #order of second and third params to be consistent with be_within
#   # value is a scalar for testing against the range, percentage is a float less than 1, midpoint is the nominal center of the range
#   return (value <= midpoint*(1.0 + percentage)) & (value >= midpoint*(1.0 - percentage))
# end


