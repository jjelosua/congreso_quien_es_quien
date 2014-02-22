class DiputadosController < ApplicationController

  def show

    @result = ActiveRecord::Base.connection.execute('SELECT count(id_legislatura) as count FROM comisiones')
    @result = @result.first

  end

end
