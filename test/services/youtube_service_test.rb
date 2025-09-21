require "test_helper"

class YoutubeServiceTest < ActiveSupport::TestCase
  test "should extract channel reference from channel URL with channel ID" do
    url = "https://www.youtube.com/channel/UC_x5XG1OV2P6uZZ5FSM9Ttw"
    result = YoutubeService.info_from_url(url)

    assert_not_nil result
    assert_equal "UC_x5XG1OV2P6uZZ5FSM9Ttw", result[:reference]
    assert_equal "channel", result[:type]
  end

  test "should extract channel reference from custom channel URL" do
    url = "https://www.youtube.com/c/GoogleDevelopers"
    result = YoutubeService.info_from_url(url)

    assert_not_nil result
    assert_equal "GoogleDevelopers", result[:reference]
    assert_equal "channel", result[:type]
  end

  test "should extract channel reference from handle URL" do
    url = "https://www.youtube.com/@GoogleDevelopers"
    result = YoutubeService.info_from_url(url)

    assert_not_nil result
    assert_equal "GoogleDevelopers", result[:reference]
    assert_equal "channel", result[:type]
  end

  test "should extract channel reference from user URL" do
    url = "https://www.youtube.com/user/GoogleDevelopers"
    result = YoutubeService.info_from_url(url)

    assert_not_nil result
    assert_equal "GoogleDevelopers", result[:reference]
    assert_equal "channel", result[:type]
  end

  test "should extract playlist reference from playlist URL" do
    url = "https://www.youtube.com/playlist?list=PLrAXtmRdnEQy6nuLMHyzdHZo6g2xefCUt"
    result = YoutubeService.info_from_url(url)

    assert_not_nil result
    assert_equal "PLrAXtmRdnEQy6nuLMHyzdHZo6g2xefCUt", result[:reference]
    assert_equal "playlist", result[:type]
  end

  test "should extract playlist reference from watch URL with playlist parameter" do
    url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PLrAXtmRdnEQy6nuLMHyzdHZo6g2xefCUt"
    result = YoutubeService.info_from_url(url)

    assert_not_nil result
    assert_equal "PLrAXtmRdnEQy6nuLMHyzdHZo6g2xefCUt", result[:reference]
    assert_equal "playlist", result[:type]
  end

  test "should handle URLs without www prefix" do
    url = "https://youtube.com/channel/UC_x5XG1OV2P6uZZ5FSM9Ttw"
    result = YoutubeService.info_from_url(url)

    assert_not_nil result
    assert_equal "UC_x5XG1OV2P6uZZ5FSM9Ttw", result[:reference]
    assert_equal "channel", result[:type]
  end

  test "should handle URLs with extra parameters" do
    url = "https://www.youtube.com/channel/UC_x5XG1OV2P6uZZ5FSM9Ttw?sub_confirmation=1"
    result = YoutubeService.info_from_url(url)

    assert_not_nil result
    assert_equal "UC_x5XG1OV2P6uZZ5FSM9Ttw", result[:reference]
    assert_equal "channel", result[:type]
  end

  test "should handle URLs with trailing slashes" do
    url = "https://www.youtube.com/channel/UC_x5XG1OV2P6uZZ5FSM9Ttw/"
    result = YoutubeService.info_from_url(url)

    assert_not_nil result
    assert_equal "UC_x5XG1OV2P6uZZ5FSM9Ttw", result[:reference]
    assert_equal "channel", result[:type]
  end

  test "should handle handle URLs with dots and hyphens" do
    url = "https://www.youtube.com/@test-channel.name"
    result = YoutubeService.info_from_url(url)

    assert_not_nil result
    assert_equal "test-channel.name", result[:reference]
    assert_equal "channel", result[:type]
  end

  test "should return nil for invalid YouTube URLs" do
    invalid_urls = [
      "https://www.google.com",
      "https://www.youtube.com/invalid",
      "https://www.youtube.com/watch?v=dQw4w9WgXcQ", # video without playlist
      "not_a_url",
      "",
      nil
    ]

    invalid_urls.each do |url|
      result = YoutubeService.info_from_url(url)
      assert_nil result, "Expected nil for URL: #{url.inspect}"
    end
  end

  test "should return nil for malformed URLs" do
    malformed_urls = [
      "https://",
      "youtube.com/channel/",
      "https://www.youtube.com/channel/",
      "https://www.youtube.com/playlist",
      "https://www.youtube.com/playlist?list="
    ]

    malformed_urls.each do |url|
      result = YoutubeService.info_from_url(url)
      assert_nil result, "Expected nil for malformed URL: #{url}"
    end
  end

  test "should return nil for non-YouTube domains" do
    non_youtube_urls = [
      "https://www.vimeo.com/123456789",
      "https://www.twitch.tv/username",
      "https://www.facebook.com/page"
    ]

    non_youtube_urls.each do |url|
      result = YoutubeService.info_from_url(url)
      assert_nil result, "Expected nil for non-YouTube URL: #{url}"
    end
  end

  test "should handle URLs with whitespace" do
    url = "  https://www.youtube.com/channel/UC_x5XG1OV2P6uZZ5FSM9Ttw  "
    result = YoutubeService.info_from_url(url)

    assert_not_nil result
    assert_equal "UC_x5XG1OV2P6uZZ5FSM9Ttw", result[:reference]
    assert_equal "channel", result[:type]
  end

  test "should handle youtu.be domain for playlists" do
    # Note: youtu.be is typically for video sharing, but we handle it in case it's used with playlists
    url = "https://youtu.be/dQw4w9WgXcQ?list=PLrAXtmRdnEQy6nuLMHyzdHZo6g2xefCUt"
    result = YoutubeService.info_from_url(url)

    # This should return nil since youtu.be URLs don't match our channel patterns
    # and the path structure is different for playlists
    assert_nil result
  end

  test "should handle case variations in domains" do
    url = "https://www.YouTube.com/channel/UC_x5XG1OV2P6uZZ5FSM9Ttw"
    result = YoutubeService.info_from_url(url)

    # Our implementation correctly handles case-insensitive domains
    assert_not_nil result
    assert_equal "UC_x5XG1OV2P6uZZ5FSM9Ttw", result[:reference]
    assert_equal "channel", result[:type]
  end

  # Tests for extract_videos method
  test "should return empty array for nil or empty URL" do
    assert_equal [], YoutubeService.extract_videos(nil)
    assert_equal [], YoutubeService.extract_videos("")
    assert_equal [], YoutubeService.extract_videos("   ")
  end

  test "should call yt-dlp with correct parameters" do
    url = "https://www.youtube.com/channel/UC_x5XG1OV2P6uZZ5FSM9Ttw"

    # Create a temporary mock method to capture the command
    captured_command = nil

    YoutubeService.define_singleton_method(:execute_command) do |cmd|
      captured_command = cmd
      nil  # Return nil to simulate command failure
    end

    YoutubeService.extract_videos(url)

    expected_command = [
      "yt-dlp",
      "--dump-json",
      "--flat-playlist",
      "--no-download",
      "--ignore-errors",
      url
    ]

    assert_equal expected_command, captured_command

    # Restore original method
    YoutubeService.singleton_class.send(:remove_method, :execute_command)
    YoutubeService.singleton_class.send(:define_method, :execute_command) do |cmd|
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
  end

  test "should build correct command for playlist URLs with video IDs" do
    url = "https://www.youtube.com/watch?v=-As1e9BwJlU&list=PLUlExuI2qKXTTmZ1HDI2rI_WC0ykP7cSV"

    cmd = YoutubeService.build_yt_dlp_command(url)

    expected_command = [
      "yt-dlp",
      "--dump-json",
      "--no-download",
      "--ignore-errors",
      "https://www.youtube.com/playlist?list=PLUlExuI2qKXTTmZ1HDI2rI_WC0ykP7cSV"
    ]

    assert_equal expected_command, cmd
  end

  test "should build correct command for direct playlist URLs" do
    url = "https://www.youtube.com/playlist?list=PLUlExuI2qKXTTmZ1HDI2rI_WC0ykP7cSV"

    cmd = YoutubeService.build_yt_dlp_command(url)

    expected_command = [
      "yt-dlp",
      "--dump-json",
      "--no-download",
      "--ignore-errors",
      "https://www.youtube.com/playlist?list=PLUlExuI2qKXTTmZ1HDI2rI_WC0ykP7cSV"
    ]

    assert_equal expected_command, cmd
  end

  test "should build correct command for channel URLs" do
    url = "https://www.youtube.com/channel/UC_x5XG1OV2P6uZZ5FSM9Ttw"

    cmd = YoutubeService.build_yt_dlp_command(url)

    expected_command = [
      "yt-dlp",
      "--dump-json",
      "--flat-playlist",
      "--no-download",
      "--ignore-errors",
      url
    ]

    assert_equal expected_command, cmd
  end

  test "should parse yt-dlp output correctly" do
    sample_output = <<~JSON
      {"id": "video1", "title": "First Video", "duration": 300, "upload_date": "20230101", "uploader": "Test Channel", "view_count": 1000, "description": "First video description"}
      {"id": "video2", "title": "Second Video", "duration": 450, "upload_date": "20230102", "uploader": "Test Channel", "view_count": 2000, "description": "Second video description"}
    JSON

    videos = YoutubeService.parse_yt_dlp_output(sample_output)

    assert_equal 2, videos.length

    first_video = videos[0]
    assert_equal "video1", first_video[:id]
    assert_equal "First Video", first_video[:title]
    assert_equal 300, first_video[:duration]
    assert_equal "20230101", first_video[:upload_date]
    assert_equal "Test Channel", first_video[:uploader]
    assert_equal 1000, first_video[:view_count]
    assert_equal "First video description", first_video[:description]
    assert_equal "https://www.youtube.com/watch?v=video1", first_video[:url]

    second_video = videos[1]
    assert_equal "video2", second_video[:id]
    assert_equal "Second Video", second_video[:title]
  end

  test "should handle malformed JSON in yt-dlp output" do
    sample_output = <<~OUTPUT
      {"id": "video1", "title": "Valid Video"}
      invalid json line that should be skipped
      {"id": "video2", "title": "Another Valid Video"}
    OUTPUT

    videos = YoutubeService.parse_yt_dlp_output(sample_output)

    assert_equal 2, videos.length
    assert_equal "video1", videos[0][:id]
    assert_equal "video2", videos[1][:id]
  end

  test "should return empty hash for invalid URL in extract_metadata" do
    result = YoutubeService.extract_metadata("")
    assert_equal({}, result)

    result = YoutubeService.extract_metadata(nil)
    assert_equal({}, result)

    result = YoutubeService.extract_metadata("invalid-url")
    assert_equal({}, result)
  end

  test "should parse playlist metadata from yt-dlp output" do
    sample_output = <<~OUTPUT
      {"title": "My Test Playlist", "description": "A sample playlist", "playlist_title": "My Test Playlist", "uploader": "Test Channel", "webpage_url": "https://youtube.com/playlist?list=test", "thumbnails": [{"url": "https://example.com/thumb.jpg", "width": 480, "height": 360}]}
    OUTPUT

    metadata = YoutubeService.parse_metadata_output(sample_output, "playlist")

    assert_equal "My Test Playlist", metadata[:name]
    assert_equal "A sample playlist", metadata[:description]
    assert_equal "Test Channel", metadata[:uploader]
    assert_equal "https://youtube.com/playlist?list=test", metadata[:url]
    assert_equal "https://example.com/thumb.jpg", metadata[:image]
  end

  test "should parse channel metadata from yt-dlp output" do
    sample_output = <<~OUTPUT
      {"title": "Test Channel", "description": "A test channel description", "uploader": "Test Channel", "webpage_url": "https://youtube.com/channel/test", "subscriber_count": 1000, "thumbnails": [{"url": "https://example.com/channel_thumb.jpg", "width": 240, "height": 240}]}
    OUTPUT

    metadata = YoutubeService.parse_metadata_output(sample_output, "channel")

    assert_equal "Test Channel", metadata[:name]
    assert_equal "A test channel description", metadata[:description]
    assert_equal "Test Channel", metadata[:uploader]
    assert_equal "https://youtube.com/channel/test", metadata[:url]
    assert_equal 1000, metadata[:subscriber_count]
    assert_equal "https://example.com/channel_thumb.jpg", metadata[:image]
  end

  test "should handle empty metadata output" do
    result = YoutubeService.parse_metadata_output("", "playlist")
    assert_equal({}, result)

    result = YoutubeService.parse_metadata_output("{}", "channel")
    assert_equal({}, result)
  end

  test "should add locale options correctly" do
    # Test with full locale (language-country)
    options = YoutubeService.add_locale_options("es-ES")
    expected = [ "--add-header", "Accept-Language:es-ES", "--geo-bypass-country", "ES" ]
    assert_equal expected, options

    # Test with language only
    options = YoutubeService.add_locale_options("fr")
    expected = [ "--add-header", "Accept-Language:fr" ]
    assert_equal expected, options

    # Test with empty locale
    options = YoutubeService.add_locale_options("")
    assert_equal [], options

    # Test with nil locale
    options = YoutubeService.add_locale_options(nil)
    assert_equal [], options

    # Test with invalid country code (too long)
    options = YoutubeService.add_locale_options("en-USA")
    expected = [ "--add-header", "Accept-Language:en-USA" ]
    assert_equal expected, options

    # Test with lowercase country code
    options = YoutubeService.add_locale_options("de-de")
    expected = [ "--add-header", "Accept-Language:de-de", "--geo-bypass-country", "DE" ]
    assert_equal expected, options
  end

  test "should build command with locale for metadata extraction" do
    url = "https://www.youtube.com/@TestChannel"

    # Without locale
    cmd = YoutubeService.build_metadata_command(url, "channel")
    expected_base = [
      "yt-dlp", "--dump-json", "--flat-playlist", "--playlist-items", "1",
      "--no-download", "--ignore-errors", url
    ]
    assert_equal expected_base, cmd

    # With locale
    cmd = YoutubeService.build_metadata_command(url, "channel", locale: "ja-JP")
    expected_with_locale = expected_base + [ "--add-header", "Accept-Language:ja-JP", "--geo-bypass-country", "JP" ]
    assert_equal expected_with_locale, cmd
  end

  test "should build command with locale for video extraction" do
    url = "https://www.youtube.com/@TestChannel"

    # Without locale
    cmd = YoutubeService.build_yt_dlp_command(url)
    expected_base = [
      "yt-dlp", "--dump-json", "--flat-playlist",
      "--no-download", "--ignore-errors", url
    ]
    assert_equal expected_base, cmd

    # With locale
    cmd = YoutubeService.build_yt_dlp_command(url, locale: "pt-BR")
    expected_with_locale = expected_base + [ "--add-header", "Accept-Language:pt-BR", "--geo-bypass-country", "BR" ]
    assert_equal expected_with_locale, cmd
  end

  test "should have convenience methods for original locale" do
    # Test that the convenience methods exist and call the main methods with locale: nil
    url = "https://www.youtube.com/@TestChannel"

    # Capture calls to main methods
    metadata_calls = []
    videos_calls = []

    # Store original methods
    original_extract_metadata = YoutubeService.method(:extract_metadata)
    original_extract_videos = YoutubeService.method(:extract_videos)

    begin
      # Mock to capture calls
      YoutubeService.define_singleton_method(:extract_metadata) do |url, locale: nil|
        metadata_calls << { url: url, locale: locale }
        {}
      end

      YoutubeService.define_singleton_method(:extract_videos) do |url, locale: nil|
        videos_calls << { url: url, locale: locale }
        []
      end

      # Test extract_metadata_original_locale
      YoutubeService.extract_metadata_original_locale(url)
      assert_equal 1, metadata_calls.length
      assert_equal url, metadata_calls.first[:url]
      assert_nil metadata_calls.first[:locale]

      # Test extract_videos_original_locale
      YoutubeService.extract_videos_original_locale(url)
      assert_equal 1, videos_calls.length
      assert_equal url, videos_calls.first[:url]
      assert_nil videos_calls.first[:locale]

    ensure
      # Restore original methods
      YoutubeService.define_singleton_method(:extract_metadata, original_extract_metadata)
      YoutubeService.define_singleton_method(:extract_videos, original_extract_videos)
    end
  end
end
