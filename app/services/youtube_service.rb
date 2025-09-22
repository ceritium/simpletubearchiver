class YoutubeService
  class << self
    def info_from_url(url)
      # return a hash with the "reference" and the type "channel" or "playlist"
      return nil unless url.present?

      # Normalize the URL
      uri = URI.parse(url.strip)
      return nil unless uri.host&.downcase&.match?(/youtube\.com|youtu\.be/)

      # Channel URL patterns
      # https://www.youtube.com/channel/UC_x5XG1OV2P6uZZ5FSM9Ttw
      # https://www.youtube.com/c/channelname
      # https://www.youtube.com/@username
      # https://www.youtube.com/user/username
      if uri.path.match(%r{^/channel/([a-zA-Z0-9_-]+)})
        return { reference: $1, type: "channel" }
      elsif uri.path.match(%r{^/c/([a-zA-Z0-9_-]+)})
        return { reference: $1, type: "channel" }
      elsif uri.path.match(%r{^/@([a-zA-Z0-9_.-]+)})
        return { reference: $1, type: "channel" }
      elsif uri.path.match(%r{^/user/([a-zA-Z0-9_-]+)})
        return { reference: $1, type: "channel" }

      # Video URL patterns
      # https://www.youtube.com/watch?v=video_id
      # https://youtu.be/video_id
      # https://www.youtube.com/shorts/video_id
      elsif uri.path == "/watch" && uri.query
        query_params = URI.decode_www_form(uri.query).to_h
        video_id = query_params["v"]
        playlist_id = query_params["list"]

        # If there's a playlist, return playlist info, otherwise return video info
        if playlist_id.present?
          return { reference: playlist_id, type: "playlist" }
        elsif video_id.present?
          return { reference: video_id, type: "video" }
        end
      elsif uri.host == "youtu.be" && uri.path.match(%r{^/([a-zA-Z0-9_-]+)})
        return { reference: $1, type: "video" }
      elsif uri.path.match(%r{^/shorts/([a-zA-Z0-9_-]+)})
        return { reference: $1, type: "video" }

      # Playlist URL patterns
      # https://www.youtube.com/playlist?list=PLrAXtmRdnEQy6nuLMHyzdHZo6g2xefCUt
      elsif uri.path == "/playlist" && uri.query
        query_params = URI.decode_www_form(uri.query).to_h
        playlist_id = query_params["list"]
        return { reference: playlist_id, type: "playlist" } if playlist_id.present?
      end

      nil
    rescue URI::InvalidURIError
      nil
    end

    def extract_metadata(url, locale: nil)
      # Extract metadata for a playlist or channel (name, description, image)
      #
      # @param url [String] The YouTube URL (channel or playlist)
      # @param locale [String, nil] Optional locale (e.g., "es-ES", "ja").
      #                            When nil, returns metadata in original creator's language
      # @return [Hash] Metadata hash with keys: :name, :description, :image, :uploader, :url
      return {} unless url.present?

      info = info_from_url(url)
      return {} unless info

      # Build command to extract playlist/channel metadata
      cmd = build_metadata_command(url, info[:type], locale: locale)

      result = execute_command(cmd)
      return {} unless result

      parse_metadata_output(result, info[:type])
    rescue => e
      Rails.logger.error "Failed to extract metadata from #{url}: #{e.message}"
      {}
    end

    def extract_metadata_original_locale(url)
      # Explicitly extract metadata in the original creator's language
      # This is equivalent to extract_metadata(url, locale: nil) but more explicit
      extract_metadata(url, locale: nil)
    end

    def extract_videos(url, locale: nil)
      # Extract videos from a playlist or channel
      #
      # @param url [String] The YouTube URL (channel or playlist)
      # @param locale [String, nil] Optional locale (e.g., "es-ES", "ja").
      #                            When nil, returns videos in original creator's language
      # @return [Array<Hash>] Array of video metadata hashes
      return [] unless url.present?

      # Determine if this is a playlist URL and build appropriate command
      cmd = build_yt_dlp_command(url, locale: locale)

      result = execute_command(cmd)
      return [] unless result

      parse_yt_dlp_output(result)
    rescue => e
      Rails.logger.error "Failed to extract videos from #{url}: #{e.message}"
      []
    end

    def extract_videos_original_locale(url)
      # Explicitly extract videos in the original creator's language
      # This is equivalent to extract_videos(url, locale: nil) but more explicit
      extract_videos(url, locale: nil)
    end

    def build_yt_dlp_command(url, locale: nil)
      # Detect if URL contains a playlist parameter
      uri = URI.parse(url)
      is_playlist = false

      if uri.query
        query_params = URI.decode_www_form(uri.query).to_h
        is_playlist = query_params["list"].present?
      end

      # For playlist URLs, we want to extract the entire playlist, not just the individual video
      if is_playlist
        # Extract playlist ID and create a direct playlist URL
        query_params = URI.decode_www_form(uri.query).to_h
        playlist_id = query_params["list"]
        playlist_url = "https://www.youtube.com/playlist?list=#{playlist_id}"

        cmd = [
          "yt-dlp",
          "--dump-json",
          "--no-download",
          "--ignore-errors",
          playlist_url
        ]
      else
        # For channels or individual videos, use the original URL
        cmd = [
          "yt-dlp",
          "--dump-json",
          "--flat-playlist",
          "--no-download",
          "--ignore-errors",
          url
        ]
      end

      # Add locale options if specified
      if locale.present?
        cmd += add_locale_options(locale)
      end

      cmd
    end

    def build_metadata_command(url, type, locale: nil)
      # Build yt-dlp command to extract playlist/channel metadata only
      if type == "playlist"
        # For playlists, we need to extract the playlist info, not individual videos
        cmd = [
          "yt-dlp",
          "--dump-json",
          "--playlist-items", "0",  # Don't extract any videos, just playlist info
          "--no-download",
          "--ignore-errors",
          url
        ]
      else
        # For channels, extract channel info from first video's playlist metadata
        cmd = [
          "yt-dlp",
          "--dump-json",
          "--flat-playlist",
          "--playlist-items", "1",  # Extract first video to get channel metadata
          "--no-download",
          "--ignore-errors",
          url
        ]
      end

      # Add locale options if specified
      if locale.present?
        cmd += add_locale_options(locale)
      end

      cmd
    end

    def parse_metadata_output(output, type)
      # Parse yt-dlp output to extract playlist/channel metadata
      output.each_line do |line|
        line = line.strip
        next if line.empty?

        begin
          data = JSON.parse(line)

          # Extract metadata based on type
          metadata = {}

          if type == "playlist"
            metadata[:name] = data["title"] || data["playlist_title"] || data["playlist"]
            metadata[:description] = data["description"] || data["playlist_description"]
            metadata[:image] = extract_best_thumbnail(data["thumbnails"])
            metadata[:uploader] = data["uploader"] || data["channel"]
            metadata[:url] = data["webpage_url"] || data["url"]
          else
            # Channel metadata extracted from playlist fields
            metadata[:name] = data["playlist_channel"] || data["playlist_uploader"] || data["channel"] || data["uploader"]
            metadata[:description] = data["channel_description"] || data["description"]
            metadata[:image] = extract_best_thumbnail(data["thumbnails"]) || data["avatar_url"]
            metadata[:uploader] = data["playlist_uploader"] || data["playlist_channel"] || data["uploader"] || data["channel"]
            metadata[:url] = data["playlist_webpage_url"] || data["webpage_url"] || data["url"]
            metadata[:subscriber_count] = data["channel_follower_count"] || data["subscriber_count"]
          end

          # Return first valid metadata found
          return metadata if metadata[:name].present?
        rescue JSON::ParserError => e
          Rails.logger.warn "Failed to parse metadata JSON line: #{line[0..100]}... Error: #{e.message}"
          next
        end
      end

      # If no metadata found in JSON lines, return empty hash
      {}
    end

    def parse_yt_dlp_output(output)
      # Helper method to parse yt-dlp JSON output
      videos = []
      output.each_line do |line|
        line = line.strip
        next if line.empty?

        begin
          video_data = JSON.parse(line)

          # Extract relevant metadata including thumbnails
          video_info = {
            id: video_data["id"],
            title: video_data["title"],
            url: video_data["url"] || "https://www.youtube.com/watch?v=#{video_data['id']}",
            duration: video_data["duration"],
            upload_date: video_data["upload_date"],
            uploader: video_data["uploader"],
            view_count: video_data["view_count"],
            description: video_data["description"]&.truncate(500),
            thumbnail: extract_best_thumbnail(video_data["thumbnails"])
          }

          videos << video_info if video_info[:id].present?
        rescue JSON::ParserError => e
          Rails.logger.warn "Failed to parse JSON line: #{line[0..100]}... Error: #{e.message}"
          next
        end
      end

      videos
    end

    def extract_best_thumbnail(thumbnails)
      # Extract the best quality thumbnail from the thumbnails array
      return nil unless thumbnails&.is_a?(Array)

      # Sort by resolution (width * height) and prefer higher quality
      best_thumbnail = thumbnails.max_by do |thumb|
        width = thumb["width"] || 0
        height = thumb["height"] || 0
        width * height
      end

      best_thumbnail&.dig("url")
    end

    def add_locale_options(locale)
      # Add locale-specific options to yt-dlp command
      options = []

      # Normalize locale format (e.g., "en-US", "es", "fr-FR")
      locale = locale.to_s.strip
      return options if locale.empty?

      # Add accept-language header for localized content
      options << "--add-header"
      options << "Accept-Language:#{locale}"

      # Extract country code for geo-bypass if locale includes country (e.g., "en-US" -> "US")
      if locale.include?("-")
        country_code = locale.split("-").last.upcase
        # Only add geo-bypass for valid country codes (2 letters)
        if country_code.length == 2 && country_code.match?(/^[A-Z]{2}$/)
          options << "--geo-bypass-country"
          options << country_code
        end
      end

      options
    end

    def execute_command(cmd)
      Rails.logger.info "Executing: #{cmd.join(' ')}"

      # Check if yt-dlp is available
      unless system("which yt-dlp > /dev/null 2>&1")
        Rails.logger.error "yt-dlp is not installed or not in PATH"
        return nil
      end

      # Capture both stdout and stderr for better debugging
      result = `#{cmd.join(" ")} 2>&1`
      exit_status = $?.exitstatus

      if exit_status == 0
        result
      else
        Rails.logger.error "Command failed with exit status #{exit_status}: #{cmd.join(' ')}"
        Rails.logger.error "Output: #{result}"
        nil
      end
    end

    def download_video(url)
      return nil unless url.present?

      # Extract video info from URL for filename pattern
      info = info_from_url(url)
      return nil unless info && info[:type] == "video"

      video_id = info[:reference]

      downloads_dir = Rails.root.join("storage", "downloads", video_id)
      FileUtils.mkdir_p(downloads_dir)

      filename_template = "%(uploader)s - %(title)s [%(id)s].%(ext)s"

      cmd = [
        "yt-dlp",
        "--output", File.join(downloads_dir, filename_template),
        "--format", "best[height<=720]",
        "--write-info-json",
        "--write-thumbnail",
        url
      ]

      success = system(*cmd)

      if success
        # Try to find the downloaded file
        pattern = File.join(downloads_dir, "*[#{video_id}].*")
        puts "pattern: #{pattern}"
        files = Dir.glob(pattern)
        video_file = files.find { |f| !f.end_with?(".info.json", ".jpg", ".webp", ".png") }
        puts "video_file: #{video_file}"

        if video_file && File.exist?(video_file)
          video_file
        else
          Rails.logger.error "Downloaded file not found for video ID: #{video_id}"
          nil
        end
      else
        Rails.logger.error "yt-dlp command failed for URL: #{url}"
        nil
      end
    rescue => e
      Rails.logger.error "Error downloading video from #{url}: #{e.message}"
      nil
    end
  end
end
