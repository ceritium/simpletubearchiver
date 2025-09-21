require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  test "should create subscription from YouTube service info" do
    url = "https://www.youtube.com/channel/UC_x5XG1OV2P6uZZ5FSM9Ttw"
    info = YoutubeService.info_from_url(url)

    assert_not_nil info

    subscription = Subscription.new(
      name: "Test Channel",
      description: "Test Description",
      url: url,
      reference: info[:reference],
      kind: info[:type],
      active: true
    )

    assert subscription.valid?
    assert_equal "UC_x5XG1OV2P6uZZ5FSM9Ttw", subscription.reference
    assert_equal "channel", subscription.kind
  end

  test "should create playlist subscription from YouTube service info" do
    url = "https://www.youtube.com/playlist?list=PLrAXtmRdnEQy6nuLMHyzdHZo6g2xefCUt"
    info = YoutubeService.info_from_url(url)

    assert_not_nil info

    subscription = Subscription.new(
      name: "Test Playlist",
      description: "Test Description",
      url: url,
      reference: info[:reference],
      kind: info[:type],
      active: true
    )

    assert subscription.valid?
    assert_equal "PLrAXtmRdnEQy6nuLMHyzdHZo6g2xefCUt", subscription.reference
    assert_equal "playlist", subscription.kind
  end
end
