var tpl = _.template("<div><a href='diputado/<%= id %>'><img class='lazy-load' dsrc='blank.gif' data-original='data/img/<%= id_diputado %>_<%= id_legislatura %>.jpg' alt='<%= nombre %>' title='<%= gr_nombre %>, Circunscripcion: <%= circ_nombre %>.'/></a><h2><%= nombre %></h2><div class='details'>Partido: <%= partido %><br>Circunscripción: <%= circ_nombre %></div></div>");

function grid (selector,data) {
  var ndx = crossfilter(data),
      all = ndx.groupAll();

  var pie_grupo = dc.pieChart(selector +  " .grupo").innerRadius(20).radius(70);
  var grupo = ndx.dimension(function(d) {return d.gr_siglas;});
  var groupGrupo   = grupo.group().reduceSum(function(d) {   return 1; });

  var pie_genero = dc.pieChart(selector +  " .genero").radius(70);
  var genero = ndx.dimension(function(d) {return d.genero;});

  var groupGenero   = genero.group().reduceSum(function(d) { return 1; });


  var NombreGenero= {"H":"Hombre","M":"Mujer"};
  var SimbololGenero= {"H":"\u2642","M":"\u2640","":""};
  
  pie_genero
    .width(200)
    .height(200)
    .dimension(genero)
    .label(function (d){
       return SimbololGenero[d.key];
    })
    .title(function (d){
       return NombreGenero[d.key] +": "+d.value;
    })
    .group(groupGenero);

  pie_grupo
    .width(200)
    .height(200)
    .cap(4)
    .othersLabel("Otros")
    .dimension(grupo)
    .colors(d3.scale.category10())
    .group(groupGrupo)
    .title(function (d){
       return d.key +": "+d.value;
    })
    .renderlet(function (chart) {});


  var legislatura = ndx.dimension (function(d) {return parseInt(d.id_legislatura);});
  
  var groupLegislatura = legislatura.group().reduceSum (function(d) {return 1;});
  var bar_legis = dc.barChart(selector + " .legis");

  bar_legis
    .width(300)
    .height(200)
    .outerPadding(0)
    .gap(1)
    .margins({top: 10, right: 0, bottom: 95, left: 30})
    .x(d3.scale.ordinal())
    .xUnits(dc.units.ordinal)
    .elasticY(true)
    .yAxisLabel("#Diputados")
    .dimension(legislatura)
    .group(groupLegislatura);
  
  var ccaa = ndx.dimension(function(d) {return d.ccaa_abrev;});
  var groupCCAA   = ccaa.group().reduceSum (function(d) {return 1;});
  var bar_ccaa = dc.barChart(selector + " .ccaa");

  bar_ccaa
    .width(300)
    .height(200)
    .outerPadding(0)
    .gap(1)
    .margins({top: 10, right: 0, bottom: 95, left: 30})
    .x(d3.scale.ordinal())
    .xUnits(dc.units.ordinal)
    .brushOn(true)
    .elasticY(true)
    .yAxisLabel("#Diputados")
    .renderHorizontalGridLines(true)
    .dimension(ccaa)
    .group(groupCCAA);

  bar_ccaa.on("postRender", function(c) {rotateCCAABarChartLabels();} );


  function rotateCCAABarChartLabels() {
    d3.selectAll(selector+ ' .ccaa .axis.x text')
      .style("text-anchor", "end" )
      .attr("transform", function(d) { return "rotate(-90, -4, 9) "; });
  }

  dc.dataCount(".dc-data-count")
    .dimension(ndx)
    .group(all);


  dc.dataGrid(".dc-data-grid")
    .dimension(legislatura)
    .group(function (d) {
        return d.leg_abrev;
        })
    .size(5000)
    .html (function(d) { 
       return tpl(d);
    })
    .sortBy(function (d) {
        return d.nombre;
        })
    .order(d3.descending)
    .renderlet(function (grid) {
      $("img.lazy-load").lazyload ({
        effect : "fadeIn",
        threshold : 100
      })
      .removeClass("lazy-load");
    });
        
        
  /*Render Graphs*/
  dc.renderAll();
}

$(function() {
    d3.csv($('body').data('host')+'/diputados/csv', function(d) {return d;}
      ,function(error, rows) {
      grid ("#diputadoslist",rows);
      });      
});    
