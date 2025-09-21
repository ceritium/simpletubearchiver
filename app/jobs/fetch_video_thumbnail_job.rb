require "open-uri"

class FetchVideoThumbnailJob < ApplicationJob
  def perform(video)
    return if video.thumbnail_image.attached?

    url = video.thumbnail_url

    downloaded_image = URI.open(url)
    filename = File.basename(URI.parse(url).path)
    filename = "thumbnail_#{id}.jpg" if filename.blank?

    video.thumbnail_image.attach(
      io: downloaded_image,
      filename: filename,
      content_type: downloaded_image.content_type || "image/jpeg"
    )
  end
end
