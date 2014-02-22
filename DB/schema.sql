DROP TABLE IF EXISTS legislaturas;

CREATE TABLE legislaturas
(
  id numeric(2,0) NOT NULL,
  descripcion character varying(50),
  fef_constitucion date,
  fec_disolucion date,
  abrev character (8),
  CONSTRAINT legislaturas_pk PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);

DROP TABLE IF EXISTS diputados;

CREATE TABLE diputados
(
  id numeric(5,0) NOT NULL,
  nombre character varying(200),
  apellidos character varying(200) NOT NULL,
  genero character(1),
  CONSTRAINT diputados_pk PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);

DROP TABLE IF EXISTS dip_legis;

CREATE TABLE dip_legis
(
  id_legislatura numeric(2,0) NOT NULL,
  id_diputado numeric(3,0) NOT NULL,
  foto character varying(100),
  partido character varying(100),
  bio text NOT NULL,
  fec_alta date,
  fec_baja date,
  CONSTRAINT dip_legis_pk PRIMARY KEY (id_legislatura, id_diputado)
)
WITH (
  OIDS=FALSE
);

DROP TABLE IF EXISTS dip_legis_contactos;

CREATE TABLE dip_legis_contactos
(
  id SERIAL,
  id_legislatura numeric(2,0) NOT NULL,
  id_diputado numeric(3,0) NOT NULL,
  id_tipo numeric(1,0) NOT NULL,
  contacto character varying(150),
  CONSTRAINT dip_legis_contactos_pk PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);

DROP TABLE IF EXISTS dip_legis_declaraciones;

CREATE TABLE dip_legis_declaraciones
(
  id SERIAL,
  id_legislatura numeric(2,0) NOT NULL,
  id_diputado numeric(3,0) NOT NULL,
  id_tipo numeric(1,0) NOT NULL,
  declaracion character varying(150),
  CONSTRAINT dip_legis_declaraciones_pk PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);

DROP TABLE IF EXISTS comisiones;

CREATE TABLE comisiones
(
  id_legislatura numeric(2,0) NOT NULL,
  id_comision numeric(3,0) NOT NULL,
  nombre character varying(200) NOT NULL,
  fec_constitucion date,
  fec_disolucion date,
  CONSTRAINT comisiones_pk PRIMARY KEY (id_legislatura,id_comision)
)
WITH (
  OIDS=FALSE
);

DROP TABLE IF EXISTS grupos;

CREATE TABLE grupos
(
  id_legislatura numeric(2,0) NOT NULL,
  id_grupo numeric(3,0) NOT NULL,
  nombre character varying(200) NOT NULL,
  siglas character (30),
  logo character varying(100),
  CONSTRAINT grupos_pk PRIMARY KEY (id_legislatura, id_grupo)
)
WITH (
  OIDS=FALSE
);

DROP TABLE IF EXISTS circunscripciones;

CREATE TABLE circunscripciones
(
  id_circunscripcion numeric(2,0) NOT NULL,
  nombre character varying(100) NOT NULL,
  id_comunidad character (2),
  CONSTRAINT circunscripciones_pk PRIMARY KEY (id_circunscripcion)
)
WITH (
  OIDS=FALSE
);

DROP TABLE IF EXISTS comunidades;

CREATE TABLE comunidades
(
  id character (2) NOT NULL,
  nombre character varying(100) NOT NULL,
  abrev character (4),
  CONSTRAINT comunidades_pk PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);

DROP TABLE IF EXISTS tipos_contacto;

CREATE TABLE tipos_contacto
(
  id numeric(1,0) NOT NULL,
  descripcion character varying(50) NOT NULL,
  CONSTRAINT tipos_contacto_pk PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);

DROP TABLE IF EXISTS tipos_declaracion;

CREATE TABLE tipos_declaracion
(
  id numeric(1,0) NOT NULL,
  descripcion character varying(50) NOT NULL,
  CONSTRAINT tipos_declaracion_pk PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);

DROP TABLE IF EXISTS tipos_iniciativa;

CREATE TABLE tipos_iniciativa
(
  id numeric(3,0) NOT NULL,
  descripcion character varying(100) NOT NULL,
  CONSTRAINT tipos_iniciativa_pk PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);

--TABLAS DE RELACION

DROP TABLE IF EXISTS rel_dip_legis_diputados;

CREATE TABLE rel_dip_legis_diputados
(
  id_legislatura numeric(2,0) NOT NULL,
  id_diputado numeric(3,0) NOT NULL,
  id numeric(5,0) NOT NULL,
  CONSTRAINT rel_dip_legis_diputados_pk PRIMARY KEY (id,id_legislatura,id_diputado)
)
WITH (
  OIDS=FALSE
);

DROP TABLE IF EXISTS rel_dip_legis_comisiones;

CREATE TABLE rel_dip_legis_comisiones
(
  id_legislatura numeric(2,0) NOT NULL,
  id_diputado numeric(3,0) NOT NULL,
  id_comision numeric(3,0) NOT NULL,
  CONSTRAINT rel_diputados_dip_legis_pk PRIMARY KEY (id_legislatura,id_diputado,id_comision)
)
WITH (
  OIDS=FALSE
);

DROP TABLE IF EXISTS rel_dip_legis_circunscripciones;

CREATE TABLE rel_dip_legis_circunscripciones
(
  id_legislatura numeric(2,0) NOT NULL,
  id_diputado numeric(3,0) NOT NULL,
  id_circunscripcion numeric(2,0) NOT NULL,
  CONSTRAINT rel_dip_legis_circunscripciones_pk PRIMARY KEY (id_legislatura,id_diputado,id_circunscripcion)
)
WITH (
  OIDS=FALSE
);

DROP TABLE IF EXISTS rel_dip_legis_grupos;

CREATE TABLE rel_dip_legis_grupos
(
  id_legislatura numeric(2,0) NOT NULL,
  id_diputado numeric(3,0) NOT NULL,
  id_grupo numeric(3,0) NOT NULL,
  CONSTRAINT rel_dip_legis_grupos_pk PRIMARY KEY (id_legislatura,id_diputado,id_grupo)
)
WITH (
  OIDS=FALSE
);

--TABLAS DE ESTADISTICAS

DROP TABLE IF EXISTS dip_legis_iniciativas_stats;

CREATE TABLE dip_legis_iniciativas_stats
(
  id_legislatura numeric(2,0) NOT NULL,
  id_diputado numeric(3,0) NOT NULL,
  id_tipo numeric(3,0) NOT NULL,
  iniciativas integer NOT NULL,
  url character varying(200),
  CONSTRAINT dip_legis_iniciativas_stats_pk PRIMARY KEY (id_legislatura,id_diputado,id_tipo)
)
WITH (
  OIDS=FALSE
);

DROP TABLE IF EXISTS dip_legis_intervenciones_stats;

CREATE TABLE dip_legis_intervenciones_stats
(
  id_legislatura numeric(2,0) NOT NULL,
  id_diputado numeric(3,0) NOT NULL,
  intervenciones integer NOT NULL,
  url character varying(200),
  CONSTRAINT dip_legis_intervenciones_stats_pk PRIMARY KEY (id_legislatura,id_diputado)
)
WITH (
  OIDS=FALSE
);

DROP TABLE IF EXISTS grupos_iniciativas_stats;

CREATE TABLE grupos_iniciativas_stats
(
  id_legislatura numeric(2,0) NOT NULL,
  id_grupo numeric(3,0) NOT NULL,
  id_tipo numeric(3,0) NOT NULL,
  iniciativas integer NOT NULL,
  url character varying(300),
  CONSTRAINT grupos_iniciativas_stats_pk PRIMARY KEY (id_legislatura,id_grupo,id_tipo)
)
WITH (
  OIDS=FALSE
);

DROP TABLE IF EXISTS comisiones_iniciativas_stats;

CREATE TABLE comisiones_iniciativas_stats
(
  id_legislatura numeric(2,0) NOT NULL,
  id_comision numeric(3,0) NOT NULL,
  iniciativas integer NOT NULL,
  url character varying(200),
  CONSTRAINT comisiones_iniciativas_stats_pk PRIMARY KEY (id_legislatura,id_comision)
)
WITH (
  OIDS=FALSE
);

DROP TABLE IF EXISTS comsisiones_intervenciones_stats;

CREATE TABLE comsisiones_intervenciones_stats
(
  id_legislatura numeric(2,0) NOT NULL,
  id_comision numeric(3,0) NOT NULL,
  intervenciones integer NOT NULL,
  url character varying(200),
  CONSTRAINT comsisiones_intervenciones_stats_pk PRIMARY KEY (id_legislatura,id_comision)
)
WITH (
  OIDS=FALSE
);



