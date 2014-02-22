# encoding: utf-8
#Libraries needed for the program
require 'fileutils'
require 'mechanize'
require 'csv'
# To correctly transform the case of special spanish caracters
require 'unicode_utils'

#To complete relative paths
HOME_SITE = 'http://www.congreso.es'
PREFFIX1_URL = 'portal/page/portal/Congreso/Congreso/Diputados/DiputadosTodasLegislaturas'
PREFFIX2_URL = 'portal/page/portal/Congreso/Congreso/Diputados/BusqForm'
QUERY1_URL = '_piref73_1335404_73_1335403_1335403.next_page=/wc/busquedaAlfabeticaTodasLeg&criterio='
QUERY2_URL = '_piref73_1333155_73_1333154_1333154.next_page=/wc/listadoFichas'
#Headers for the output file
HEADERS1 = ["id","nombre","apellidos"]
HEADERS2 = ["id","idDiputado","idLegislatura","url"] 

#Create the folders where the data and logs will be stored
#Create the folders where the data and logs will be stored
OUTPUT_SUBDIR = 'data'
LOG_SUBDIR = 'logs'
FileUtils.makedirs(LOG_SUBDIR)
FileUtils.makedirs(OUTPUT_SUBDIR)

#Create the log and output files
script_name = $0.gsub(/\.rb/,"")
log_file = File.open("#{LOG_SUBDIR}/#{script_name}.log", 'w')
output_file1 = File.open("#{OUTPUT_SUBDIR}/#{script_name}_diputados.csv", 'w')
output_file2 = File.open("#{OUTPUT_SUBDIR}/#{script_name}_diputados_legislatura.csv", 'w')
#Write the header to the output files
output_file1.puts CSV::generate_line(HEADERS1,:encoding => 'utf-8')
output_file2.puts CSV::generate_line(HEADERS2,:encoding => 'utf-8')

#Instantiate the mechanize object
agent = Mechanize.new

#Compose url
url_base = "#{HOME_SITE}/#{PREFFIX1_URL}?#{QUERY1_URL}"
url_base2 = "#{HOME_SITE}/#{PREFFIX2_URL}?#{QUERY2_URL}"
#Get the cookie from the main page
next_page = true
page_num = 0
id = 0
while next_page
  puts "Processing page: #{page_num}"
  url = url_base + "&paginaActual=#{page_num}"
  begin
    page = agent.get(url)
  rescue Mechanize::ResponseCodeError => the_error
    log_file.puts("#{url}: Got a bad status code #{the_error.response_code}")
  end
  
  #Get the nokogiri parsed document
  doc = page.parser
  
  if page_num == 0
    total = doc.css("div.SUBTITULO_CONTENIDO span").text.to_i
    #25 results per page
    num_pages = total / 25
    num_pages = ((total % 25) != 0) ? num_pages + 1 : num_pages 
  end

  links = doc.css("div.listado_1 li a")
  links.each do |link|
    href = link["href"]
    #Extract identification params for the legislative periods loop
    href =~ /(idDiputado=\d+&idLegislatura=\d+)/
    params = $1 ? $1 : nil

    # Name and surname info
    text = link.text.strip
    text =~ /^(.*),\s*(.*)$/
    apellidos = $1 ? $1 : nil
    nombre = $2 ? $2 : nil
    id += 1
    output_file1.puts CSV::generate_line([id,nombre,apellidos],:encoding => 'utf-8')
    #We need to go through the initial deputy page
    agent.get(href)
    
    #Check the different legislative periods that this deputy was present
    url2 = "#{url_base2}?#{params}"
    begin
      page2 = agent.get(url2)
    rescue Mechanize::ResponseCodeError => the_error
      log_file.puts("#{url2}: Got a bad status code #{the_error.response_code}")
    end
    #Get the nokogiri parsed document
    doc2 = page2.parser
    links2 = doc2.css("div.btn_ficha a")
    links2.each do |link2|
      href2 = link2["href"]
      href2 =~ /idLegislatura=(\d+)&idDiputado=(\d+)/
      idLegislatura = $1 ? $1 : nil
      idDiputado = $2 ? $2 : nil
      output_file2.puts CSV::generate_line([id,idDiputado,idLegislatura,href2],:encoding => 'utf-8')
    end
    sleep(1)
  end
  #Check if we need to continue
  page_num += 1
  next_page = false if page_num > num_pages
  sleep(1)
end
output_file2.close
output_file1.close
log_file.close
