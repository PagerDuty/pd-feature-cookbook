require 'chefspec'
require 'chefspec/berkshelf'

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
  # config.log_level = :debug
  config.order = 'random'
  config.platform = 'ubuntu'
  config.version = '16.04'
  config.raise_errors_for_deprecations!

  config.role_path = 'test/roles'
end
