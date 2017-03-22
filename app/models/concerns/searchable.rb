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
                'split_languages',
                # 'cities.unmod',
                'cities.standard^1.5',
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
                field: "split_languages"
              }
            },
            city: {
              terms: {
                field: "cities.unmod"
              }
            }
          }
        })
    end

    def as_indexed_json(options={})
      as_json(
        # change city to cities (list)
        {
        only: [:firstname, :lastname, :twitter, :languages, :city, :bio],
          methods: [:fullname, :topic_list, :bio_en, :bio_de, :main_topic_en, :main_topic_de, :cities, :split_languages],
          include: {
            medialinks: { only: [:title, :description] }
          }
        }
       )
    end

    super_special_settings = {
      index: {
        number_of_shards: 1,
        analysis: {
          filter: {
            english_stop: {
              type:       'stop',
              stopwords:  '_english_' 
            },
            english_possessive_stemmer: {
              type:       'stemmer',
              language:   'possessive_english'
            },
            german_stop: {
              type:       'stop',
              stopwords:  '_german_' 
            }
          },
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
            },
            # elisions????
            cities_analyzer: {
              type: 'custom',
              tokenizer: 'keyword',
              filter: ['lowercase']
            },
            english_without_stemming: {
              tokenizer:  'standard',
              filter: [
                'english_possessive_stemmer',
                'lowercase',
                'english_stop'
              ]
            },
            german_without_stemming: {
              tokenizer:  'standard',
              filter: [
                'lowercase',
                'german_stop',
                'german_normalization'
              ]
            }
          }
        }
      }
    }

    settings super_special_settings do
      mappings dynamic: 'false' do
        indexes :fullname,   type: 'string', analyzer: 'standard'
        indexes :twitter,    type: 'string', analyzer: 'twitter_analyzer'
        indexes :main_topic_de, type: 'string', analyzer: 'german_without_stemming'
        indexes :main_topic_en, type: 'string', analyzer: 'english_without_stemming'
        indexes :topic_list, type: 'string', analyzer: 'topic_list_analyzer'
        indexes :bio_de,     type: 'string', analyzer: 'german'
        indexes :bio_en,     type: 'string', analyzer: 'english'
        indexes :split_languages,   type: 'string', analyzer: 'standard', 'norms': { 'enabled': false }
        indexes :cities, fields: { unmod: { type:  'string', analyzer: 'cities_analyzer' }, standard: { type:  'string', analyzer: 'standard'} }
        indexes :country,    type: 'string', analyzer: 'standard' # iso standard
        indexes :website,    type: 'string', analyzer: 'standard'
        indexes :medialinks, type: 'nested' do
          indexes :title
          indexes :description
        end
      end
    end
  end
end
