class HomeController < ApplicationController

  def index

    @diputados = bd.diputados

  end

end
