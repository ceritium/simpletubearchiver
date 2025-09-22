module ApplicationHelper
  def mm_ss(seconds)
    minutes = seconds / 60
    secs = seconds % 60
    format("%d:%02d", minutes, secs)
  end
end
