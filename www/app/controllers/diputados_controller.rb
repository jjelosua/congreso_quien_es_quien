class DiputadosController < ApplicationController

  def show
    @legs = bd.legislaturas_diputado(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @legs }
    end
  end

end
