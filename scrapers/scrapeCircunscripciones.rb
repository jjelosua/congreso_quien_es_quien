# encoding: utf-8
#Libraries needed for the program
require 'fileutils'
require 'mechanize'
require 'csv'
# To correctly transform the case of special spanish caracters
require 'unicode_utils'

#To complete relative paths
HOME_SITE = 'http://www.congreso.es'
PREFFIX_URL = 'portal/page/portal/Congreso/Congreso/Diputados/DipCircuns/ComAutGal'
QUERY_URL = '_piref73_1333397_73_1333392_1333392.next_page=/wc/busquedaDiputadosCircunscripcion'
#Headers for the output file
HEADERS1 = ["id_circunscripcion","nombre"]
HEADERS2 = ["id_legislatura","id_diputado","id_circunscripcion"] 

#Create the folders where the data and logs will be stored
#Create the folders where the data and logs will be stored
OUTPUT_SUBDIR = 'data'
LOG_SUBDIR = 'logs'
FileUtils.makedirs(LOG_SUBDIR)
FileUtils.makedirs(OUTPUT_SUBDIR)

#Create the log and output files
script_name = $0.gsub(/\.rb/,"")
log_file = File.open("#{LOG_SUBDIR}/#{script_name}.log", 'w')
output_file1 = File.open("#{OUTPUT_SUBDIR}/#{script_name}.csv", 'w')
output_file2 = File.open("#{OUTPUT_SUBDIR}/#{script_name}_miembros.csv", 'w')
#Write the header to the output file
output_file1.puts CSV::generate_line(HEADERS1,:encoding => 'utf-8')
output_file2.puts CSV::generate_line(HEADERS2,:encoding => 'utf-8')

#Instantiate the mechanize object
agent = Mechanize.new

#Compose url
base_url = "#{HOME_SITE}/#{PREFFIX_URL}?#{QUERY_URL}"

#Get the cookie from the main page
for id_legislatura in 0..10
  puts "Processing legislative period: #{id_legislatura}"
  for id_circunscripcion in 1..52
    puts "Processing circunscripcion: #{id_circunscripcion}"
    url = base_url + "&circunscripcionSelec=#{id_circunscripcion}&idLegislatura=#{id_legislatura}"
    begin
      page = agent.get(url)
    rescue Mechanize::ResponseCodeError => the_error
      log_file.puts("#{url}: Got a bad status code #{the_error.response_code}")
    end
  
    #Get the nokogiri parsed document
    doc = page.parser
  
    #Circunscripcion
    if id_legislatura == 0
      text = doc.css("div.SUBTITULO_CONTENIDO").text
      text =~ /Circunscripción de\s*:\s*(.*)$/
      #Remove first and last characters from the name
      nombre = $1 ? $1.strip.gsub(".","").gsub(/^./,"") : nil
      output_file1.puts CSV::generate_line([id_circunscripcion,nombre],:encoding => 'utf-8')
    end
  
    #Diputados
    links = (id_legislatura == 10) ? doc.css("div.listado_1 li a") : doc.css("table.listado_2 td.subtit_gris_tabla a")
    links.each do |link|
      href = link["href"]
      href =~/idDiputado=(\d+)/
      id_diputado = $1 ? $1 : nil
      if id_diputado
        output_file2.puts CSV::generate_line([id_legislatura,id_diputado,id_circunscripcion],:encoding => 'utf-8')
      end
    end
    sleep(0.5)
  end
end
output_file2.close
output_file1.close
log_file.close
