class Profile < ActiveRecord::Base
  include AutoHtml
  include HasPicture
  include Searchable
  include ActiveModel::Serialization

  has_many :medialinks

  translates :bio, :main_topic, fallbacks_for_empty_translations: true
  accepts_nested_attributes_for :translations

  extend FriendlyId
  friendly_id :slug_candidate, use: :slugged

  super_special_settings = {
    index: {
      number_of_shards: 1,
      analysis: {
        char_filter: {
          strip_twitter: {
            type: "pattern_replace",
            pattern: "[^a-z0-9]",
            replacement: ""
          }
        },
        analyzer:{
          twitter_analyzer: {
            type: "custom",
            tokenizer: "keyword",
            filter: ["lowercase"],
            char_filter: ["strip_twitter"]
          },
          topic_list_analyzer: {
            type: "custom",
            tokenizer: "keyword", # maren: wie soll das matchen? keyword, nicht keyword? evtl booster nutzen
            filter: ["lowercase"]
          }
        }
      }
    }
  }

  settings super_special_settings do
    mappings dynamic: 'false' do 
      indexes :fullname,   type: 'string', analyzer: 'german'
      indexes :twitter,    type: 'string', analyzer: 'twitter_analyzer'
      indexes :topic_list, type: 'string', analyzer: 'topic_list_analyzer'
      indexes :main_topic, type: 'string', analyzer: 'standard'
      indexes :languages,  type: 'string', analyzer: 'standard' # array? german & english drop down!!!
      indexes :city,       type: 'string', analyzer: 'standard' # geodaten??
      indexes :country,    type: 'string', analyzer: 'standard' # not analyzed, iso standard
      indexes :website,    type: 'string', analyzer: 'standard'
      indexes :bio,        type: 'string', analyzer: 'standard', fields: { english: { type:  "string", analyzer: "english" }, german: { type:  "string", analyzer: "german"} }
    end
  end

  auto_html_for :media_url do
    html_escape
    image
    youtube width: 400, height: 250
    vimeo width: 400, height: 250
    simple_format
    link target: '_blank', rel: 'nofollow'
  end

  devise :database_authenticatable, :registerable, :omniauthable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  acts_as_taggable_on :topics

  before_save(on: [:create, :update]) do
    twitter.gsub!(%r{^@|https:|http:|:|//|www.|twitter.com/}, '') if twitter
    firstname.strip! if firstname
    lastname.strip! if lastname
  end

  after_save :update_or_remove_index

  def after_confirmation
    AdminMailer.new_profile_confirmed(self).deliver
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |profile|
      profile.provider = auth.provider
      profile.uid = auth.uid
      profile.twitter = auth.info.nickname
    end
  end

  def self.new_with_session(params, session)
    if session['devise.user_attributes']
      new(session['devise.user_attributes'], without_protection: true) do |profile|
        profile.attributes = params
        profile.valid?
      end
    else
      super
    end
  end

  scope :is_published, -> { where(published: true) }

  scope :no_admin, -> { where(admin: false) }

  def fullname
    "#{firstname} #{lastname}".strip
  end

  def name_or_email
    fullname.present? ? fullname : email
  end

  def main_topic_or_first_topic
    main_topic.present? ? main_topic : topic_list.first
  end

 # Try building a slug based on the following fields in
  # increasing order of specificity.
  def slug_candidate
    #[:full_name, :id] - you can do this only onUpdate (when :id already set) When you are creating a new record in your DB table this will not work!
    [
      :fullname,
      [:fullname, :id]
    ]
  end

  def should_generate_new_friendly_id?
   slug.blank? || firstname_changed? || lastname_changed?
  end

  def website_with_protocol
    if website =~ %r{^https?://}
      return website
    else
      return 'http://' + website
    end
  end

  def twitter_name_formatted
    twitter.gsub(%r{^@|https:|http:|:|//|www.|twitter.com/}, '')
  end

  def twitter_link_formatted
    'http://twitter.com/' + twitter.gsub(%r{^@|https:|http:|:|//|www.|twitter.com/}, '')
  end

  def country_name
    country_name = ISO3166::Country[self.country]
    country_name.translations[I18n.locale.to_s] || country.name
  end

  def self.random
    order('RANDOM()')
  end

  def update_or_remove_index
    if published then index_document else delete_document end rescue nil # rescue a deleted document if not indexed
  end

  def password_required?
    super && provider.blank?
  end

  def update_with_password(params, *options)
    if encrypted_password.blank?
      update_attributes(params, *options)
    else
      super
    end
  end


# class Article < ActiveRecord::Base
#   include Elasticsearch::Model
#   include Elasticsearch::Model::Callbacks

#   def self.search(query)
#     __elasticsearch__.search(
#       {
#         query: {
#           multi_match: {
#             query: query,
#             fields: ['title^10', 'content']
#           }
#         },
#         highlight: {
#           pre_tags: ['<em class="label label-highlight">'],
#           post_tags: ['</em>'],
#           fields: {
#             title:   { number_of_fragments: 0 },
#             content: { fragment_size: 25 }
#           }
#         }
#       }
#     )
#   end

  
# end
  # for simple admin search
  # def self.search(query)
  #   where("firstname || ' ' || lastname ILIKE :query OR twitter ILIKE :query", query: "%#{query}%")
  # end
end
