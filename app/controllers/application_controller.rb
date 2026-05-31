class ApplicationController < ActionController::Base
  layout 'application'
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  include Devise::Controllers::Helpers

  before_action :set_ransack

  private

  def set_ransack
    @q = Product.ransack(params[:q])
  end
end
