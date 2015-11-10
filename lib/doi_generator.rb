require 'hashids'
require 'datacite_mds'
require 'securerandom'

module DoiGenerator

  DOI_SHOULDER = Rails.application.config.doi[Rails.env]['shoulder']
  SALT = 'Bodleian Libraries salt'
  SLICE_DIGITS = 10 # dont want a very long doi suffix
  MDS = Datacite::Mds.new


  def self.generate(uuid)
    hashids = Hashids.new(SALT)
    # remove any redundant parts from uuid
    raw_string = uuid.gsub("uuid:", "").gsub("-", "").slice(0, SLICE_DIGITS)
    doi = DOI_SHOULDER + ":" + hashids.encode_hex(raw_string)
    # make sure DOI not already on Datacite
    MDS.resolve(doi).instance_of?(Net::HTTPNotFound) ? doi 
    						: generate(SecureRandom.uuid)
  end


end


