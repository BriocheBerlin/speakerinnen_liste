module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    index_name [Rails.application.engine_name, Rails.env].join('_')

    def self.search(query, options={})
      __elasticsearch__.search(query, options)
    end

    def as_indexed_json(options={})
      self.as_json(
        only: [:firstname, :lastname, :twitter, :languages, :city, :country, :website, :bio],
          methods: [:fullname, :topic_list, :main_topic]
      )
    end
  end
end