SimpleCov.formatter = Coveralls::SimpleCov::Formatter if ENV["COVERAGE"] == 'remote'


SimpleCov.start 'rails' do 
  add_filter '/test/'
  add_filter '/config/'
  add_filter '/vendor/'

  # add_group 'Controllers', 'app/controllers'
  # add_group 'Models', 'app/models'
  # add_group 'Helpers', 'app/helpers'
  # add_group 'Views', 'app/views'
  # add_group 'Libs', 'app/lib'
end if ENV["COVERAGE"]