class Subscription < ApplicationRecord
  has_many :videos, dependent: :destroy

  has_one_attached :image

  validates :url, presence: true
  validates :reference, presence: true

  enum :kind, { channel: 0, playlist: 1 }

  before_validation :extract_info_from_url
  after_create :enqueue_fetch_metadata
  after_create :enqueue_fetch_videos

  def enqueue_fetch_metadata
    FetchSubscriptionMetadataJob.perform_later(self)
  end

  def enqueue_fetch_videos
    FetchSubscriptionVideosJob.perform_later(self)
  end

  def extract_info_from_url
    return unless url

    info = YoutubeService.info_from_url(url)
    self.reference = info[:reference]
    self.kind = info[:type]
  end
end
