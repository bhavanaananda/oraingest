require 'datacite_mds'
require 'active_support/core_ext/hash/indifferent_access'


class RegisterDoiJob

  @queue = :register_doi

  def self.perform(pid)


    obj = Dataset.find(pid)
    return unless obj.doi_requested?
    payload = obj.doi_data


    # Register doi
    mds = Datacite::Mds.new
    res = mds.upload_metadata( build_metadata(payload.with_indifferent_access))
    if res.instance_of? Net::HTTPCreated
      res = mds.mint payload[:identifier], payload[:target]
      if res.instance_of? Net::HTTPCreated
        obj.workflowMetadata.update_status(Sufia.config.doi_status,
                                           "Doi with metadata registered")
      else
        obj.workflowMetadata.update_status(Sufia.config.doi_status,
                                           "Minting DOI failed, status: #{res.code} - body #{res.body}")
        #TODO: delete metadata
      end
    else
      obj.workflowMetadata.update_status(Sufia.config.doi_status,
                                         "Udating metadata failed, status: #{res.code} - body #{res.body}")
    end

    obj.save!
  end

  private
  def self.build_metadata(payload)
    data = Builder::XmlMarkup.new( :indent => 2 )
    data.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
    opts = {
      "xsi:schemaLocation"=>"http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd",
      "xmlns"=>"http://datacite.org/schema/kernel-3",
      "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance"
    }
    data.resource( opts ) do
      # identifier
      data.tag!("identifier", payload[:identifier], :identifierType => "DOI")
      # creators
      data.creators do
        payload[:creator].each do |creator|
          data.creator do
            if creator.kind_of?(String)
              data.creatorName creator
            else
              data.creatorName creator[:name]
              if creator.has_key?(:nameIdentifierScheme) && creator.has_key?(:nameIdentifierSchemeUri)
                data.tag!("nameIdentifier", nameIdentifierScheme: creator[:nameIdentifierScheme], schemeURI: creator[:nameIdentifierSchemeUri])
              end
              if creator.has_key?(:affiliation)
                data.affiliation creator[:affiliation]
              end
            end
          end
        end
      end
      # titles
      data.titles do
        if payload[:title].is_a?(Hash)
          payload[:title] = [payload.title]
        end
        if payload[:title].is_a?(Array)
          payload[:title].each do |t|
            if t.kind_of?(String)
              data.title t
            else
              if t.has_key?(:type)
                data.tag!("title", t[:title], titleType: t[:type])
              else
                data.title t[:title]
              end
            end
          end
        else
          data.title payload[:title]
        end
      end
      # publisher
      data.publisher payload[:publisher]
      # publication uear
      data.publicationYear payload[:publicationYear]
      # subjects
      if payload.has_key?(:subject) && payload[:subject].length > 0
        data.subjects do
          payload[:subject].each do |s|
            if s.has_key?(:scheme) && s[:scheme] && s.has_key?(:schemeUri) && s[:schemeUri]
              data.tag!("subject", s[:subject], subjectScheme: s[:scheme], schemeURI: s[:schemeUri])
            else
              data.subject s[:subject]
            end
          end
        end
      end
      # Contributors
      if payload.has_key?(:contributor) && payload[:contributor].length > 0
        data.contributors do
          #TODO: Contributor type has to be one of accepted type if not other
          payload[:contributor].each do |contributor|

            typ = contributor.has_key?(:type) ?
                contributor[:type] : ""

            data.contributor(contributorType: typ) do
              if contributor.kind_of?(String)
                data.contributorName contributor
              else
                data.contributorName contributor[:name]
                if contributor.has_key?(:nameIdentifierScheme) && contributor.has_key?(:nameIdentifierSchemeUri)
                  data.tag!("nameIdentifier", nameIdentifierScheme: contributor[:nameIdentifierScheme], schemeURI: contributor[:nameIdentifierSchemeUri])
                end
                if contributor.has_key?(:affiliation)
                  data.affiliation contributor[:affiliation]
                end
              end
            end
          end
        end
      end
      # resource type
      if payload.has_key?(:resourceType) && !payload[:resourceType].empty? && payload.has_key?(:resourceTypeGeneral) && !payload[:resourceTypeGeneral].empty?
        data.tag!("resourceType", payload[:resourceType], resourceTypeGeneral: payload[:resourceTypeGeneral])
      end
      # size
      if payload.has_key?(:size)
        data.sizes do
          if payload[:size].is_a?(Array)
            payload[:size].each do |s|
              data.size s
            end
          else
            data.size payload[:size]
          end
        end
      end
      # format
      if payload.has_key?(:format)
        data.format do
          if payload[:format].is_a?(Array)
            payload[:format].each do |f|
              data.format f
            end
          else
            data.format payload[:format]
          end
        end
      end
      # version
      if payload.has_key?(:version)
        data.version payload[:version]
      end
      # rights
      if payload.has_key?(:rights)
        data.rightsList do
          payload[:rights].each do |r|
            if r.has_key?(:rights) and r.has_key?(:rightsUri)
              data.tag!("rights", r[:rights], rightsURI: r[:rightsUri])
            elsif r.has_key?(:rights)
              data.tag!("rights", r[:rights])
            elsif r.has_key?(:rightsUri)
              data.tag!("rights", rightsURI: r[:rightsUri] )
            end
          end
        end
      end
      # descriptions
      if payload.has_key?(:description)
        data.descriptions do
          payload[:description].each do |d|
            if d.has_key?(:description) and d.has_key?(:type)
              data.tag!("description", d[:description], descriptionType: d[:type] )
            end
          end
        end
      end
    end
    data.target!
  end

end
