class HomeController < ApplicationController

  def index

    @diputados = bd.diputados_csv

    @diputados.each do |d|
      p d.inspect
    end

  end

end
