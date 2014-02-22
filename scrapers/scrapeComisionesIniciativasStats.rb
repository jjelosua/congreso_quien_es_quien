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

def createTargetUrl(id_legislatura,id_comision)
  #Compose url
  base_url = "#{HOME_SITE}/#{PREFFIX_URL}?#{TARGET_URL}"
  base_param = ("10".eql? id_legislatura) ? "IW"+id_legislatura : "IWI"+id_legislatura
  query_param = "%28I%29.ACIN1.+%26+#{id_comision}.NCOM."
  url = "#{base_url}&BASE=#{base_param}&QUERY=#{query_param}"
  return url
end

#To complete relative paths
LOG_LEVEL = "DEBUG"
HOME_SITE = 'http://www.congreso.es'
PREFFIX_URL = 'portal/page/portal/Congreso/PopUpCGI'
QUERY_URL = 'oriIC=S&CMD=VERLST&FMT=INITXLGE.fmt&DOCS=1-25&DOCORDER=FIFO&OPDEF=Y'
TARGET_URL = 'oriIC=S&CMD=VERLST&FMT=INITXLGE.fmt&DOCS=1-25&DOCORDER=FIFO&OPDEF=Y'
#Headers for the output file
HEADERS = ["id_legislatura","id_comision","iniciativas","url"]   

#Create the folders where the data and logs will be stored
INPUT_FILE = 'scrapeComisionesComposicion_comisiones.csv'
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
  id_legislatura,id_comision,nombre,fec_constitucion,fec_disolucion = row
  #Skip header
  if count == 0
    count += 1
    next
  end
  writeLog("DEBUG","Processing comission: #{id_comision} for legislative period: #{id_legislatura}")
  #Create url
  base_param = ("10".eql? id_legislatura) ? "IW"+id_legislatura : "IWI"+id_legislatura
  query_param = "(I).ACIN1.+%26+#{id_comision}.NCOM."
  url = "#{base_url}&BASE=#{base_param}&QUERY=#{query_param}"
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
  
  #Comisiones
  iniciativas = 0
  results = doc.css('div#RESULTADOS_BUSQUEDA div.SUBTITULO_CONTENIDO')
  if results.length > 0
    if results.text =~ /Iniciativas\s+encontradas.*?(\d+)/
      iniciativas = $1.to_i unless $1.nil?
    end
  end
  puts "iniciativas: #{iniciativas}"

  if iniciativas > 0
    target_url = createTargetUrl(id_legislatura,id_comision)
  else
    target_url = nil
    writeLog("WARNING","No results found for #{id_comision} in legislative period #{id_legislatura}")
  end
  data = [id_legislatura,id_comision,iniciativas,target_url]
  $output_file.puts CSV::generate_line(data,:encoding => 'utf-8') 
  sleep(0.5)
end
$output_file.close
$log_file.close
