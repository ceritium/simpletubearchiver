class FetchSubscriptionVideosJob < ApplicationJob
  def perform(subscription)
    subscription.syncing!

    items = YoutubeService.extract_videos(subscription.url)
    items.each do |item|
      puts item
      video = subscription.videos.find_or_initialize_by(reference: item[:id])
      video.title = item[:title]
      video.description = item[:description]
      video.url = item[:url]
      video.duration = item[:duration]
      video.thumbnail_url = item[:thumbnail]
      video.save!
    end

    subscription.done!
  rescue
    subscription.failed!
  end
end
