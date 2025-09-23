class SubscriptionsController < ApplicationController
  def index
    @subscriptions = Subscription.all
  end

  def sync
    @subscription = Subscription.find(params[:id])
    @subscription.enqueue_fetch_videos
  end

  def new
    @subscription = Subscription.new
  end

  def create
    @subscription = Subscription.new(subscription_params)
    if @subscription.save
      redirect_to subscriptions_path
    else
      render :new
    end
  end

  def destroy
    @subscription = Subscription.find(params[:id])
    @subscription.destroy
    redirect_to subscriptions_path, notice: "Subscription was successfully deleted."
  rescue ActiveRecord::RecordNotFound
    redirect_to subscriptions_path, alert: "Subscription not found."
  end

  private

  def subscription_params
    params.require(:subscription).permit(:url, :name, :description, :active)
  end
end
