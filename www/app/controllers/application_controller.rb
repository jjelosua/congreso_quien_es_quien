class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :bd

  def bd
    Cqq::Bd.new
  end

end
