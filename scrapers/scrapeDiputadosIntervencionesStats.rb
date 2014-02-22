# encoding: utf-8
#Libraries needed for the program
require 'fileutils'
require 'mechanize'
require 'csv'
# To correctly transform the case of special spanish caracters
require 'unicode_utils'

def writeLog (level,msg) 
  levels = {"DEBUG"=>0,"WARNING"=>1,"ERROR"=>2}
  if levels[level] >= levels[LOG_LEVEL]
    $log_file.puts("#{level}: #{msg}")
  end
end

def createTargetUrl(id_legislatura,id_diputado)
  #Compose url
  base_url = "#{HOME_SITE}/#{PREFFIX_URL}?#{TARGET_URL}"
  base_param = ("10".eql? id_legislatura) ? "IT"+id_legislatura : "IWT"+id_legislatura
  query_param = "%28#{id_diputado}+ADJ+D%29.CORA."
  url = "#{base_url}&BASE=#{base_param}&QUERY=#{query_param}"
  return url
end

#To complete relative paths
LOG_LEVEL = "DEBUG"
HOME_SITE = 'http://www.congreso.es'
PREFFIX_URL = 'portal/page/portal/Congreso/PopUpCGI'
QUERY_URL = 'CMD=VERLST&FMT=INTTXLDC.fmt&DOCORDER=FIFO'
TARGET_URL = 'CMD=VERLST&FMT=INTTXLDA.fmt&DOCS=1-25&DOCORDER=FIFO'
#Headers for the output file
HEADERS = ["id_legislatura","id_diputado","intervenciones","url"]   

#Create the folders where the data and logs will be stored
INPUT_FILE = 'scrapeDiputados_diputados_legislatura.csv'
INPUT_SUBDIR = 'data'
OUTPUT_SUBDIR = 'data'
LOG_SUBDIR = 'logs'
FileUtils.makedirs(LOG_SUBDIR)
FileUtils.makedirs(OUTPUT_SUBDIR)

#Create the log and output files
script_name = $0.gsub(/\.rb/,"")
$log_file = File.open("#{LOG_SUBDIR}/#{script_name}.log", 'w')
#Main output file
$output_file = File.open("#{OUTPUT_SUBDIR}/#{script_name}.csv", 'w')
$output_file.puts CSV::generate_line(HEADERS,:encoding => 'utf-8')

#Instantiate the mechanize object
agent = Mechanize.new

#Compose url
base_url = "#{HOME_SITE}/#{PREFFIX_URL}?#{QUERY_URL}"

count = 0
prev_id = nil
CSV.foreach("#{INPUT_SUBDIR}/#{INPUT_FILE}") do |row|
  id,id_diputado,id_legislatura,profile_url = row
  #Skip header
  if count == 0
    count += 1
    next
  end
  writeLog("DEBUG","Processing deputy: #{id_diputado} for legislative period: #{id_legislatura}")
  #Create url
  base_param = ("10".eql? id_legislatura) ? "IS"+id_legislatura : "IWS"+id_legislatura
  query_param = "(#{id_diputado}+ADJ+D).CORA."
  url = "#{base_url}&BASE=#{base_param}&QUERY=#{query_param}&DOCS=1-25"
  #Get page
  begin
    page = agent.get(url)
  rescue Mechanize::ResponseCodeError => the_error
    writeLog("ERROR","Got a bad status code #{the_error.response_code} for #{url}")
  end
  
  #Set the page encoding to utf-8 to deal with special spanish chars
  page.encoding = 'utf-8'
  
  #Get the nokogiri parsed document
  doc = page.parser
  links_pag = doc.css("div.paginacion_brs a")
  last_link = links_pag.last
  page_num = nil
  while (last_link && last_link.text =~ /Siguiente/)
    page_num = links_pag[links_pag.length-2].text.strip.to_i
    new_search = "#{(page_num-1)*25+1}-#{page_num*25}"
    url.gsub!(/DOCS=\d+-\d+/,"DOCS=#{new_search}")
    begin
      page = agent.get(url)
    rescue Mechanize::ResponseCodeError => the_error
      writeLog("ERROR","Got a bad status code #{the_error.response_code} for #{url}")
    end
    #Set the page encoding to utf-8 to deal with special spanish chars
    page.encoding = 'utf-8'
  
    #Get the nokogiri parsed document
    doc = page.parser
    links_pag = doc.css("div.paginacion_brs a")
    last_link = links_pag.last
  end
  
  #Intervenciones
  links = doc.css("div.resultados_encontrados div.subtitulo_iniciativa a")
  intervenciones = page_num ? (page_num-1)*25 : 0
  links.each do |link|
    if link.text =~ /^\s*PDF\s*$/
      intervenciones += 1
    end
  end 
  puts "intervenciones: #{intervenciones}"
  if intervenciones > 0
    target_url = createTargetUrl(id_legislatura,id_diputado)
  else
    target_url = nil
    writeLog("WARNING","No results found for #{id_diputado} in legislative period #{id_legislatura}")
  end
  data = [id_legislatura,id_diputado,intervenciones,target_url]
  $output_file.puts CSV::generate_line(data,:encoding => 'utf-8') 
  sleep(0.5)
end
$output_file.close
$log_file.close