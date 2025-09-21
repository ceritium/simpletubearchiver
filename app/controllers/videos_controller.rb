class VideosController < ApplicationController
  def index
    @videos = Video.page(params[:page])
    @videos = @videos.where(subscription_id: params[:subscription_id]) if params[:subscription_id].present?
  end

  def show
    @video = Video.find(params[:id])
  end

  def fetch
    @video = Video.find(params[:id])
    @video.enqueue_fetch
  end
end
