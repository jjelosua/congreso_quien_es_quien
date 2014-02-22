# encoding: utf-8
#Libraries needed for the program
require 'fileutils'
require 'mechanize'
require 'csv'
# To correctly transform the case of special spanish caracters
require 'unicode_utils'

#To complete relative paths
HOME_SITE = 'http://www.congreso.es'
PREFFIX_URL = 'portal/page/portal/Congreso/Congreso/Diputados/DipGrupParl'
QUERY_URL = '_piref73_1333475_73_1333472_1333472.next_page=/wc/composicionGrupo'
#Headers for the output file
HEADERS = ["id_legislatura","id_diputado","id_grupo"]  

#Create the folders where the data and logs will be stored
#Create the folders where the data and logs will be stored
INPUT_FILE = 'scrapeGrupos.csv'
INPUT_SUBDIR = 'data'
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
base_url = "#{HOME_SITE}/#{PREFFIX_URL}?#{QUERY_URL}"

count = 0
prev_id = nil
CSV.foreach("#{INPUT_SUBDIR}/#{INPUT_FILE}") do |row|
  id_legislatura,id_grupo,nombre = row
  
  #Skip header
  if count == 0
    count += 1
    next
  else
    puts "processing legislative period: #{id_legislatura}" if id_legislatura != prev_id
    prev_id = id_legislatura 
  end
  
  next_page = true
  page_num = 0
  while next_page
    puts "Processing page: #{page_num} for grupo: #{id_grupo}"
    url = base_url + "&idGrupo=#{id_grupo}&paginaActual=#{page_num}&idLegislatura=#{id_legislatura}"
    begin
      page = agent.get(url)
    rescue Mechanize::ResponseCodeError => the_error
      log_file.puts("#{url}: Got a bad status code #{the_error.response_code}")
    end
  
    #Get the nokogiri parsed document
    doc = page.parser
    
    #Check number of pages
    if page_num == 0
      total = doc.css("div.SUBTITULO_CONTENIDO span").text.to_i
      #25 results per page
      num_pages = total / 25
      num_pages = ((total % 25) != 0) ? num_pages + 1 : num_pages 
    end
  
    #Diputados
    links = doc.css("div.listado_1 td.subtit_gris_tabla a")
    links.each do |link|
      href = link["href"]
      href =~/idDiputado=(\d+)/
      id_diputado = $1 ? $1 : nil
      output_file.puts CSV::generate_line([id_legislatura,id_diputado,id_grupo],:encoding => 'utf-8')
    end
    #Check if we need to continue
    page_num += 1
    next_page = false if page_num > num_pages
    sleep(0.5)
  end
end
output_file.close
log_file.close
