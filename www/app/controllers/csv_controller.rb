# encoding: utf-8
require 'csv'

class CsvController < ApplicationController

  def diputados

    diputados = bd.diputados_csv

    i =0
    data = CSV.generate do |_results|
      _results << ["id","id_diputado","nombre","genero","id_legislatura","leg_abrev","leg_descripcion","partido","id_grupo","gr_nombre","gr_siglas","circ_nombre","ccaa_id","ccaa_abrev","ccaa_nombre"] if i==0

      diputados.each do |d|

        _results << [
          d["id"], 
          d["id_diputado"],
          d["nombre"],
          d["genero"],
          d["id_legislatura"],
          d["leg_abrev"],
          d["leg_descripcion"],
          d["partido"],
          d["id_grupo"],
          d["gr_nombre"],
          d["gr_siglas"],
          d["circ_nombre"],
          d["ccaa_id"],
          d["ccaa_abrev"],
          d["ccaa_nombre"]
        ]
      end

      i = i+1
    end

    send_data(data,  :type => 'text/csv; charset=utf-8; header=present', :filename => "results.csv")
  end
end
