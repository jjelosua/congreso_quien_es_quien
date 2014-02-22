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
        SELECT d.id, dl.id_diputado, (d.apellidos || ', ' || d.nombre) as nombre, substring(dl.bio from 1 for 500) as bio,
        dl.foto, dl.id_legislatura, l.descripcion as leg_descripcion,
        g.id_grupo, g.nombre as gr_nombre,
        c.id_circunscripcion, c.nombre as circ_nombre,
        (SELECT SUM(iniciativas)
        FROM dip_legis s_dl, rel_dip_legis_diputados s_rd, diputados s_d, dip_legis_iniciativas_stats s_dlinis
        WHERE s_d.id = d.id AND s_dl.id_legislatura = dl.id_legislatura
        AND s_dl.id_legislatura = s_rd.id_legislatura
        AND s_dl.id_diputado = s_rd.id_diputado
        AND s_rd.id = s_d.id
        AND s_dl.id_legislatura = s_dlinis.id_legislatura
        AND s_dl.id_diputado = s_dlinis.id_diputado
        GROUP BY s_d.id, s_dl.id_legislatura, s_dl.id_diputado) as iniciativas,
        (SELECT round(AVG(iniciativas),2)
        FROM dip_legis_iniciativas_stats s_dlinis 
        WHERE s_dlinis.id_legislatura = dl.id_legislatura) as avg_iniciativas,
        dlints.intervenciones,
        (SELECT round(AVG(intervenciones),2)
        FROM dip_legis_intervenciones_stats s_dlints 
        WHERE s_dlints.id_legislatura = dl.id_legislatura) as avg_intervenciones
        FROM dip_legis dl, rel_dip_legis_diputados rd, rel_dip_legis_grupos rg, rel_dip_legis_circunscripciones rc,
        diputados d, grupos g, circunscripciones c, legislaturas l, dip_legis_intervenciones_stats dlints
        WHERE d.id = 19
        AND rd.id = d.id
        AND dl.id_diputado = rd.id_diputado
        AND dl.id_legislatura = l.id
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
        AND dl.id_legislatura = dlints.id_legislatura
        AND dl.id_diputado = dlints.id_diputado;
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
