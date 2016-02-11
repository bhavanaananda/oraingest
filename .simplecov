

SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter

SimpleCov.start 'rails' do 
  add_filter '/test/'
  add_filter '/config/'
  add_filter '/vendor/'

  add_filter do |source_file|
    source_file.lines.count < 5
  end  

end 