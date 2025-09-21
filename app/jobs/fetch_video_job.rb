class FetchVideoJob < ApplicationJob
  def perform(video)
    video.downloading!
    path = YoutubeService.download_video(video.url)
    file = File.open(path)

    video.video_file.attach(io: file, filename: File.basename(path))
    video.completed!
  rescue
    video.failed!
  end
end
