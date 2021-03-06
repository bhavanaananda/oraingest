module Ora
  module Search
    module SearchFields
      extend ActiveSupport::Concern
      included do
        configure_blacklight do |config|
          # "fielded" search configuration. Used by pulldown among other places.
          # For supported keys in hash, see rdoc for Blacklight::SearchFields
          #
          # Search fields will inherit the :qt solr request handler from
          # config[:default_solr_parameters], OR can specify a different one
          # with a :qt key/value. Below examples inherit, except for subject
          # that specifies the same :qt as default for our own internal
          # testing purposes.
          #
          # The :key is what will be used to identify this BL search field internally,
          # as well as in URLs -- so changing it after deployment may break bookmarked
          # urls.  A display label will be automatically calculated from the :key,
          # or can be specified manually to be different.
          #
          # This one uses all the defaults set by the solr request handler. Which
          # solr request handler? The one set in config[:default_solr_parameters][:qt],
          # since we aren't specifying it otherwise.
          config.add_search_field('all_fields', :label => 'All Fields', :include_in_advanced_search => false) do |field|
            title_name = solr_name("desc_metadata__title", :stored_searchable, type: :string)
            label_name = solr_name("desc_metadata__title", :stored_searchable, type: :string)
            contributor_name = solr_name("desc_metadata__contributor", :stored_searchable, type: :string)
            field.solr_parameters = {
              :qf => "#{title_name} noid_tsi #{label_name} file_format_tesim #{contributor_name}",
              :pf => "#{title_name}"
            }
          end
        end
      end
    end
  end
end
