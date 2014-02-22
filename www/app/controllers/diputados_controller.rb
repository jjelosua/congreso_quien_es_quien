class DiputadosController < ApplicationController

  def show

    # @diputados = bd.diputados

    # @diputados.each do |d|
    #   p d.inspect
    # end

    @legs = bd.legislaturas_diputado(params[:id])



    # @result = ActiveRecord::Base.connection.execute('SELECT count(id_legislatura) as count FROM comisiones')
    # @result = @result.first

  end

end
