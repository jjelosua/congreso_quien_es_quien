# encoding: utf-8
#Libraries needed for the program
require 'fileutils'
require 'mechanize'
require 'csv'
# To correctly transform the case of special spanish caracters
require 'unicode_utils'

#To complete relative paths
HOME_SITE = 'http://www.congreso.es'
PREFFIX_URL = 'portal/page/portal/Congreso/Congreso/Organos/Comision'
QUERY_URL = '_piref73_7498063_73_1339256_1339256.next_page=/wc/composicionOrgano'
#Headers for the output file
HEADERS1 = ["id_legislatura","id_comision","nombre","fec_constitucion","fec_disolucion"]
HEADERS2 = ["id_legislatura","id_comision","id_diputado"]  

#Create the folders where the data and logs will be stored
#Create the folders where the data and logs will be stored
INPUT_FILE = 'scrapeComisiones.csv'
INPUT_SUBDIR = 'data'
OUTPUT_SUBDIR = 'data'
LOG_SUBDIR = 'logs'
FileUtils.makedirs(LOG_SUBDIR)
FileUtils.makedirs(OUTPUT_SUBDIR)

#Create the log and output files
script_name = $0.gsub(/\.rb/,"")
log_file = File.open("#{LOG_SUBDIR}/#{script_name}.log", 'w')
output_file1 = File.open("#{OUTPUT_SUBDIR}/#{script_name}_comisiones.csv", 'w')
output_file2 = File.open("#{OUTPUT_SUBDIR}/#{script_name}_miembros.csv", 'w')
#Write the header to the output file
output_file1.puts CSV::generate_line(HEADERS1,:encoding => 'utf-8')
output_file2.puts CSV::generate_line(HEADERS2,:encoding => 'utf-8')

#Instantiate the mechanize object
agent = Mechanize.new

#Compose url
base_url = "#{HOME_SITE}/#{PREFFIX_URL}?#{QUERY_URL}"

count = 0
prev_id = nil
CSV.foreach("#{INPUT_SUBDIR}/#{INPUT_FILE}") do |row|
  id_legislatura,id_comision,nombre = row
  
  #Skip header
  if count == 0
    count += 1
    next
  else
    puts "processing legislative period: #{id_legislatura}" if id_legislatura != prev_id
    prev_id = id_legislatura 
  end
  
  url = base_url + "&idOrgano=#{id_comision}&idLegislatura=#{id_legislatura}"
  begin
    page = agent.get(url)
  rescue Mechanize::ResponseCodeError => the_error
    log_file.puts("#{url}: Got a bad status code #{the_error.response_code}")
  end
  
  #Get the nokogiri parsed document
  doc = page.parser
  
  #fechas
  cell = doc.css('table.listado_2 td.subtit_gris_tabla').first
  if cell.nil?
    next
  end
  fechas = cell.text
  fechas =~ /Constitución:\s*(\d{2})\/(\d{2})\/(\d{4})/
  fec_constitucion = "#{$3}-#{$2}-#{$1}" unless $1.nil?
  fechas =~ /disolución:\s*(\d{2})\/(\d{2})\/(\d{4})/
  fec_disolucion = "#{$3}-#{$2}-#{$1}" unless $1.nil?
  output_file1.puts CSV::generate_line([id_legislatura,id_comision,nombre,fec_constitucion,fec_disolucion],:encoding => 'utf-8')
  
  #Diputados
  links = doc.css("table.listado_2 td.subtit_gris_tabla a")
  links.each do |link|
    href = link["href"]
    href =~/idDiputado=(\d+)/
    id_diputado = $1 ? $1 : nil
    output_file2.puts CSV::generate_line([id_legislatura,id_comision,id_diputado],:encoding => 'utf-8')
  end
  sleep(0.5)
end
output_file2.close
output_file1.close
log_file.close
