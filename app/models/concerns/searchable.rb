module Searchable
  extend ActiveSupport::Concern

  included do
    translates :bio, :main_topic, fallbacks_for_empty_translations: true

    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks
    include Elasticsearch::Model::Globalize::MultipleFields

    index_name [Rails.application.engine_name, Rails.env].join('_')

    def self.search(query)
      __elasticsearch__.search(
        {
          query: {
            multi_match: {
              query: query,
              fields: [
                'firstname',
                'lastname',
                'fullname',
                'twitter',
                'topic_list',
                'main_topic_en',
                'main_topic_de',
                'languages',
                'city',
                'country',
                'bio_de',
                'bio_en'
              ],
              tie_breaker: 0.3,
              fuzziness: 'AUTO'
            }
          },
          aggs: {
            lang: {
              terms: {
                field: "languages"
              }
            },
            city: {
              terms: {
                field: "city"
              }
            }
          }
        })
    end

    def as_indexed_json(options={})
      self.as_json(
        only: [:firstname, :lastname, :twitter, :languages, :city, :bio],
          methods: [:fullname, :topic_list, :bio_en, :bio_de, :main_topic_en, :main_topic_de],
          include: {
            medialinks: { only: [:title, :description] }
          }
      )
    end

    super_special_settings = {
      index: {
        number_of_shards: 1,
        analysis: {
          char_filter: {
            strip_twitter: {
              type: 'pattern_replace',
              pattern: '[^a-z0-9]',
              replacement: ''
            }
          },
          analyzer:{
            twitter_analyzer: {
              type: 'custom',
              tokenizer: 'keyword',
              filter: ['lowercase'],
              char_filter: ['strip_twitter']
            },
            topic_list_analyzer: {
              type: 'custom',
              tokenizer: 'keyword', # maren: wie soll das matchen? keyword, nicht keyword? evtl booster nutzen
              filter: ['lowercase']
            }
          }
        }
      }
    }

    settings super_special_settings do
      mappings dynamic: 'false' do
        indexes :firstname,  type: 'string', analyzer: 'german'
        indexes :lastname,   type: 'string', analyzer: 'german'
        indexes :fullname,   type: 'string', analyzer: 'german'
        indexes :twitter,    type: 'string', analyzer: 'twitter_analyzer'
        indexes :topic_list, type: 'string', analyzer: 'topic_list_analyzer'
        indexes :main_topic_de, type: 'string', analyzer: 'german'
        indexes :main_topic_en, type: 'string', analyzer: 'english'
        indexes :languages,  type: 'string', analyzer: 'standard' # array? german & english drop down!!!
        indexes :city,       type: 'string', analyzer: 'standard', 'norms': { 'enabled': false }
        indexes :country,    type: 'string', analyzer: 'standard' # iso standard
        indexes :website,    type: 'string', analyzer: 'standard'
        indexes :bio_de,     type: 'string', analyzer: 'german'
        indexes :bio_en,     type: 'string', analyzer: 'english'
        indexes :medialinks, type: 'nested' do
          indexes :title
          indexes :description
        end
      end
    end
  end
end
