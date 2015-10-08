
Sufia.config do |config|
  
  config.contact_email = 'ora@bodleian.ox.ac.uk'
  config.from_email = 'no-reply@bodleian.ox.ac.uk'
  if Rails.env.production?
    config.data_root_dir = '/data/oradeposit/'
    config.cud_base_url = 'http://10.0.0.203'
  else
    config.data_root_dir = File.expand_path('data/oradeposit/', Rails.root)
    config.cud_base_url = "http://dams-auth.bodleian.ox.ac.uk"
  end

  # For migrating records
  config.ora_publish_queue_name = 'ora_publish'
  config.tmp_file_dir = 'tmp/files/'
end

