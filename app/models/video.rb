class Video < ApplicationRecord
  belongs_to :subscription
  has_one_attached :thumbnail_image
  has_one_attached :video_file

  enum :download_status, { pending: 0, queued: 1, downloading: 2, completed: 3, failed: 4 }, default: :pending

  after_create :enqueue_fetch_thumbnail
  after_create_commit :broadcast_created
  after_update_commit :broadcast_updated
  after_destroy_commit :broadcast_destroyed

  def enqueue_fetch_thumbnail
    FetchVideoThumbnailJob.perform_later(self)
  end

  def enqueue_fetch
    queued!
    FetchVideoJob.perform_later(self)
  end

  def can_be_played?
    true
  end

  def video_id
    reference
  end

  private

  def broadcast_created
    broadcast_prepend_to "videos", target: "videos", partial: "videos/video", locals: { video: self }
  end

  def broadcast_updated
    broadcast_update_to "videos", target: self, partial: "videos/video", locals: { video: self }
  end

  def broadcast_destroyed
    broadcast_remove_to "videos", target: self
  end
end
