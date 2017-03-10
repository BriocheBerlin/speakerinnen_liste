module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    index_name [Rails.application.engine_name, Rails.env].join('_')

    # def self.search(query, options={})
    #   __elasticsearch__.search(query, options)
    # end

    def self.search(query)
      __elasticsearch__.search(
        #simple search twitter, name, topic
        # maren: einfach alle felder hier rein?? sinnvoll aus user perspektive
        {
          query: {
            multi_match: {
              query: query,
              fuzziness: "Auto",
              fields: [
                :fullname,
                :twitter,
                :topic_list,
                :main_topic 
              ]
            }
          }
        }
      )
    end

# # main topic vergessen!!!!!!!!!!
#     def self.search(query)
#       __elasticsearch__.search(
#         {
#           "query": {
#             "multi_match": {
#               "query": query,
#               "fields": [
#                 "fullname^3",
#                 "twitter^4",
#                 "topic_list^3",
#                 "main_topic",
#                 "languages^2",
#                 "city",
#                 "country",
#                 "bio"
#               ],
#               "tie_breaker": 0.3,
#               "fuzziness": "AUTO"
#             }
#           }
#         })
#       end


# #########################################
# {
#   "settings": {
#     "index": {
#       "analysis": {
#         "analyzer": {
#           "topic_list_analyzer": {
#             "type": "custom",
#             "tokenizer": "keyword",
#             "filter": [
#               "lowercase"
#             ]
#           },
#           "twitter_analyzer": {
#             "type": "custom",
#             "tokenizer": "standard",
#             "filter": [
#               "lowercase"
#             ],
#             "char_filter": {
#               "strip_twitter": {
#                 "type": "pattern_replace",
#                 "pattern": "[^a-z0-9]",
#                 "replacement": ""
#               }
#             }
#           },
#           "twitter_analyzer_perfect_match": {
#             "type": "custom",
#             "tokenizer": "keyword",
#             "filter": [
#               "lowercase"
#             ]
#           }
#         }
#       }
#     },
#     "number_of_shards": 1
#   },
#   "mappings": {
#     "profile": {
#       "properties": {
#         "fullname": {
#           "type": "string",
#           "analyzer": "german",
#           "norms": { "enabled": false }
#         },
#         "main_topic": {
#           "type": "string",
#           "analyzer": "standard"
#         },
#         "topic_list": {
#           "type": "string",
#           "analyzer": "topic_list_analyzer"
#         },
#         "languages": {
#           "type": "string",
#           "analyzer": "standard"
#         },
#         "city": {
#           "type": "string",
#           "analyzer": "standard",
#           "norms": { "enabled": false }
#         },
#         "country": {
#           "type": "string",
#           "analyzer": "standard"
#         },
#         "website": {
#           "type": "string",
#           "analyzer": "german"
#         },
#         "bio": {
#           "type": "string",
#           "fields": {
#             "english": {
#               "type": "string",
#               "analyzer": "english"
#             },
#             "german": {
#               "type": "string",
#               "analyzer": "german"
#             }
#           }
#         },
#         "twitter": {
#           "type": "string",
#           "fields": {
#             "raw": {
#               "type": "string",
#               "analyzer": "twitter_analyzer_perfect_match"
#             },
#             "partial_match": {
#               "type": "string",
#               "analyzer": "twitter_analyzer"
#             }
#           }
#         }
#       }
#     }
#   }
# }

    # # not sure if this naming works
    # # pass options?????
    # def self.search_detail(query, options)
    #   __elasticsearch__.search(
    #     {
    #       query: {
    #         bool: {
    #           should: [
    #             { match: { fullname: options.fullname }},
    #             { match: { twitter: options.twitter }},
    #             { match: { topic_list: options.topic_list }}, # copy_to topic_list and main_topic
    #             { match: { country: options.country }},
    #             { match: { city: options.city }},
    #             { match: { languages: options.languages }
    #             }
    #           ]
    #         }
    #       }
    #     }
    # end

    def as_indexed_json(options={})
      self.as_json(
        only: [:firstname, :lastname, :twitter, :languages, :city, :country, :website, :bio],
          methods: [:fullname, :topic_list, :main_topic]
      )
    end
    Profile.__elasticsearch__.create_index! force: true
  end
end


# RELEVANZMODEL: boosten
# twitterhandle , zweites field angeben mit raw twitterhandle. grossen boost geben
# name (oder name stadt)
# stadt
# topics
# bio
# country