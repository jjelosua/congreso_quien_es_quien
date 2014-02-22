module Cqq
  class Bd

    def initialize()
    end

    def diputados_csv()
      ActiveRecord::Base.connection.execute("
        SELECT d.id, dl.id_diputado, (d.apellidos || ', ' || d.nombre) as nombre, d.genero, 
        dl.id_legislatura, trim(trailing from l.abrev) as leg_abrev, l.descripcion as leg_descripcion, 
        dl.partido as partido, g.id_grupo, g.nombre as gr_nombre, trim(both from g.siglas) as gr_siglas, 
        c.nombre as circ_nombre, cc.id as ccaa_id, cc.abrev as ccaa_abrev, cc.nombre as ccaa_nombre

        FROM dip_legis dl, rel_dip_legis_diputados rd, rel_dip_legis_grupos rg, rel_dip_legis_circunscripciones rc,
        diputados d, grupos g, circunscripciones c, comunidades cc, legislaturas l

        WHERE dl.id_legislatura = l.id
        AND dl.id_legislatura = rd.id_legislatura
        AND dl.id_diputado = rd.id_diputado
        AND rd.id = d.id
        AND dl.id_legislatura = rg.id_legislatura
        AND dl.id_diputado = rg.id_diputado
        AND rg.id_legislatura = g.id_legislatura
        AND rg.id_grupo = g.id_grupo
        AND dl.id_legislatura = rc.id_legislatura
        AND dl.id_diputado = rc.id_diputado
        AND rc.id_circunscripcion = c.id_circunscripcion
        AND c.id_comunidad = cc.id;
        ")
    end

    def legislaturas_diputado(id_diputado)
      ActiveRecord::Base.connection.execute("
       SELECT l.id, l.descripcion, substr(dl.bio, 0, 512), dl.partido
       FROM dip_legis dl
       LEFT JOIN legislaturas l  ON l.id=dl.id_legislatura
       WHERE dl.id_diputado=#{id_diputado}
       ORDER BY l.id
        ");
    end

    def grupo(id_diputado, id_legislatura)
      ActiveRecord::Base.connection.execute("
        SELECT g.*
        FROM grupos g
        LEFT JOIN rel_dip_legis_grupos lg ON lg.id_legislatura=#{id_legislatura} AND lg.id_diputado=#{id_diputado}
      ");
    end

    def diputado(id)
      ActiveRecord::Base.connection.execute("
        SELECT d.id, dl.id_diputado, (d.apellidos || ', ' || d.nombre) as nombre, d.genero, 
        dl.id_legislatura, trim(trailing from l.abrev) as leg_abrev, l.descripcion as leg_descripcion, 
        dl.paartido as partido, g.id_grupo, g.nombre as gr_nombre, trim(both from g.siglas) as gr_siglas, 
        c.nombre as circ_nombre, cc.id as ccaa_id, cc.abrev as ccaa_abrev, cc.nombre as ccaa_nombre
        FROM diputados d
        WHERE #{id}    dl.id_legislatura = l.id
              AND dl.id_legislatura = rd.id_legislatura
              AND dl.id_diputado = rd.id_diputado
              AND rd.id = d.id
              AND dl.id_legislatura = rg.id_legislatura
              AND dl.id_diputado = rg.id_diputado
              AND rg.id_legislatura = g.id_legislatura
              AND rg.id_grupo = g.id_grupo
              AND dl.id_legislatura = rc.id_legislatura
              AND dl.id_diputado = rc.id_diputado
              AND rc.id_circunscripcion = c.id_circunscripcion
              AND c.id_comunidad = cc.id;
        ")
    end

  end
end
