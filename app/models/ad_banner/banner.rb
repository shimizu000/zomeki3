class AdBanner::Banner < ApplicationRecord
  include Sys::Model::Base
  include Sys::Model::Base::File
  include Sys::Model::Rel::Creator
  include Cms::Model::Auth::Content

  include StateText

  STATE_OPTIONS = [['公開', 'public'], ['非公開', 'closed']]
  TARGET_OPTIONS = [['同一ウィンドウ', '_self'], ['別ウィンドウ', '_blank']]

  default_scope { order(:sort_no) }

  banners = self.arel_table
  scope :published, -> {
          now = Time.now
          where(banners[:state].eq('public')
                .and(banners[:published_at].eq(nil).or(banners[:published_at].lteq(now))
                .and(banners[:closed_at].eq(nil).or(banners[:closed_at].gt(now)))))
        }
  scope :closed, -> {
          now = Time.now
          where(banners[:state].eq('closed')
                .or(banners[:published_at].gt(now))
                .or(banners[:closed_at].lteq(now)))
        }

  # Content
  belongs_to :content, :foreign_key => :content_id, :class_name => 'AdBanner::Content::Banner'
  validates :content_id, presence: true

  # Proper
  validates :state, presence: true

  belongs_to :group, :foreign_key => :group_id, :class_name => 'AdBanner::Group'

  has_many :clicks, :foreign_key => :banner_id, :class_name => 'AdBanner::Click', :dependent => :destroy

  validates :advertiser_name, :presence => true
  validates :url, :presence => true

  after_initialize :set_defaults
  before_create :set_token

  after_save     Cms::Publisher::ContentRelatedCallbacks.new, if: :changed?
  before_destroy Cms::Publisher::ContentRelatedCallbacks.new

  def image_uri
    return '' unless content.public_node
    "#{content.public_node.public_uri}#{name}"
  end

  def image_path
    return '' unless content.public_node
    "#{content.public_node.public_path}#{name}"
  end

  def image_mobile_path
    return '' unless content.public_node
    "#{content.public_node.public_mobile_path}#{name}"
  end

  def image_smart_phone_path
    return '' unless content.public_node
    "#{content.public_node.public_smart_phone_path}#{name}"
  end

  def link_uri
    return '' unless content.public_node
    "#{content.public_node.public_uri}#{token}"
  end

  def target_text
    TARGET_OPTIONS.detect{|o| o.last == self.target }.try(:first).to_s
  end

  def publish_or_close_image
    if published?
      [image_path, image_mobile_path, image_smart_phone_path].each do |path|
        next if path == image_smart_phone_path && !self.content.site.publish_for_smart_phone?
        FileUtils.mkdir_p ::File.dirname(path)
        FileUtils.cp upload_path, path
      end
    else
      [image_path, image_mobile_path, image_smart_phone_path].each do |path|
        FileUtils.rm image_path if ::File.exist?(path)
        FileUtils.rmdir ::File.dirname(path)
      end
    end
  end

  def published?
    now = Time.now
    (state == 'public') && (published_at.nil? || published_at <= now) && (closed_at.nil? || closed_at > now)
  end

  def closed?
    !published?
  end

  private

  def set_defaults
    self.state    ||= STATE_OPTIONS.first.last if self.has_attribute?(:state)
    self.target   ||= TARGET_OPTIONS.last.last if self.has_attribute?(:target)
    self.sort_no  ||= 10 if self.has_attribute?(:sort_no)
  end

  def set_token
    self.token = Util::String::Token.generate_unique_token(self.class, :token)
  end

  # Override Sys::Model::Base::File#duplicated?
  def duplicated?
    banners = self.class.arel_table
    not self.class.where(content_id: self.content_id, name: self.name).where(banners[:id].not_eq(self.id)).empty?
  end
end
