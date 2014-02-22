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

def getPartido(doc)                     
  partido = doc.css("div#datos_diputado p.nombre_grupo").text.strip
  return partido
end

LOG_LEVEL = "DEBUG"
#To complete relative paths
HOME_SITE = 'http://www.congreso.es'
PREFFIX_URL = 'portal/page/portal/Congreso/Congreso/Diputados/BusqForm'
QUERY_URL = '_piref73_1333155_73_1333154_1333154.next_page=/wc/fichaDiputado'

#Headers for the output file
HEADERS = ["id_legislatura","id_diputado","partido"] 

#Create the folders where the data and logs will be stored
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
output_file = File.open("#{OUTPUT_SUBDIR}/#{script_name}.csv", 'w')
output_file.puts CSV::generate_line(HEADERS,:encoding => 'utf-8')

#Instantiate the mechanize object
agent = Mechanize.new

#Compose url
base_url = "#{HOME_SITE}/#{PREFFIX_URL}?#{QUERY_URL}"

count = 0
prev_id = nil
CSV.foreach("#{INPUT_SUBDIR}/#{INPUT_FILE}") do |row|
  id,id_diputado,id_legislatura,url = row
  #Skip header
  if count == 0
    count += 1
    next
  end
  writeLog("DEBUG","Processing deputy: #{id_diputado} for legislative period: #{id_legislatura}")
  puts "processing deputy: #{id_diputado} for legislative period: #{id_legislatura}"
  
  #complete url
  url = "#{base_url}&idLegislatura=#{id_legislatura}&idDiputado=#{id_diputado}"
  #Get page
  begin
    puts url
    page = agent.get(url)
  rescue Mechanize::ResponseCodeError => the_error
    writeLog("ERROR","Got a bad status code #{the_error.response_code} for #{url}")
  end
  
  #Set the page encoding to utf-8 to deal with special spanish chars
  page.encoding = 'utf-8'
  
  #Get the nokogiri parsed document
  doc = page.parser
  
  #Diputados
  partido = getPartido(doc)
  puts partido
  output_file.puts CSV::generate_line([id_legislatura,id_diputado,partido],:encoding => 'utf-8')
  sleep(0.5)
end
output_file.close
$log_file.close
