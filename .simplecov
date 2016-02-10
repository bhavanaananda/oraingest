

SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter

SimpleCov.start 'rails' do 
  add_filter '/test/'
  add_filter '/config/'
  add_filter '/vendor/'

end 