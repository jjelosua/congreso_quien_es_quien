# encoding: utf-8
#Libraries needed for the program
require 'fileutils'
require 'mechanize'
require 'csv'
# To correctly transform the case of special spanish caracters
require 'unicode_utils'

#To complete relative paths
HOME_SITE = 'http://www.congreso.es'
PREFFIX_URL = 'portal/page/portal/Congreso/Congreso/Organos'
QUERY_URL = '_piref73_1339233_73_1339230_1339230.next_page=/wc/cambioLegislatura'
#Headers for the output file
HEADERS = ["id","nombre","fec_constitucion","fec_disolucion"] 

#Create the folders where the data and logs will be stored
#Create the folders where the data and logs will be stored
OUTPUT_SUBDIR = 'data'
LOG_SUBDIR = 'logs'
FileUtils.makedirs(LOG_SUBDIR)
FileUtils.makedirs(OUTPUT_SUBDIR)

#Create the log and output files
script_name = $0.gsub(/\.rb/,"")
log_file = File.open("#{LOG_SUBDIR}/#{script_name}.log", 'w')
output_file = File.open("#{OUTPUT_SUBDIR}/#{script_name}.csv", 'w')
#Write the header to the output file
output_file.puts CSV::generate_line(HEADERS,:encoding => 'utf-8')

#Instantiate the mechanize object
agent = Mechanize.new

#Compose url
url = "#{HOME_SITE}/#{PREFFIX_URL}?#{QUERY_URL}"
#Get the cookie from the main page
for id in 0..10
  #Initialize
  nombre = nil
  fec_constitucion = nil
  fec_disolucion = nil
  
  begin
    params = {'idLegislatura' => id}
    page = agent.post(url,params)
  rescue Mechanize::ResponseCodeError => the_error
    log_file.puts("#{url}: Got a bad status code #{the_error.response_code}")
  end
  
  #Get the nokogiri parsed document
  doc = page.parser
  
  #nombre
  titulo = doc.css("div.TITULO_CONTENIDO_composicion div.titulo").text
  titulo =~ /(.*)\s+\(.*$/
  nombre = $1.strip unless $1.nil?
  
  #fechas
  fechas = doc.css('table.listado_2 td.subtit_gris_tabla').first.text
  fechas =~ /Constitución:\s*(\d{2})\/(\d{2})\/(\d{4})/
  fec_constitucion = "#{$3}-#{$2}-#{$1}" unless $1.nil?
  fechas =~ /disolución:\s*(\d{2})\/(\d{2})\/(\d{4})/
  fec_disolucion = "#{$3}-#{$2}-#{$1}" unless $1.nil?
  output_file.puts CSV::generate_line([id,nombre,fec_constitucion,fec_disolucion],:encoding => 'utf-8')
end
output_file.close
log_file.close
