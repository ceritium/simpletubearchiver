require "open-uri"

class FetchSubscriptionMetadataJob < ApplicationJob
  def perform(subscription)
    data = YoutubeService.extract_metadata(subscription.url)
    subscription.name = data[:name]
    subscription.description = data[:description]
    # subscription.image_url = data[:image_url]
    subscription.save!

    url = data[:image]
    downloaded_image = URI.open(url)
    filename = File.basename(URI.parse(url).path)
    filename = "thumbnail_#{id}.jpg" if filename.blank?

    subscription.image.attach(
      io: downloaded_image,
      filename: filename,
      content_type: downloaded_image.content_type || "image/jpeg"
    )
  end
end
