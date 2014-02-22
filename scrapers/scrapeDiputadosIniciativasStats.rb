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

def createTargetUrl(id_legislatura,id_diputado,tipo)
  #Compose url
  base_url = "#{HOME_SITE}/#{PREFFIX_URL}?#{TARGET_URL}"
  base_param = ("10".eql? id_legislatura) ? "IW"+id_legislatura : "IWI"+id_legislatura
  query_param = "#{tipo}.ACIN3.+y+%28#{id_diputado}+ADJ+D%29.SAUT."
  url = "#{base_url}&BASE=#{base_param}&QUERY=#{query_param}"
  return url
end

def getStats(items,id_legislatura,id_diputado) 
  initiative_types = {"Preguntas orales"=> 201,
                   "Preguntas escritas"=>202,
                   "Solicitudes de comparecencia"=>203,
                   "Solicitudes de informes"=>204,
                   "Solicitudes de creación de comisiones, subcomisiones y ponencias"=>205}
  
  #Check if total is greater than expected
  if items.last.text =~ /Total\s*:\s+(\d+)/
    total = $1 ? $1.to_i : nil
    if total > 12000 
      writeLog("WARNING","More than 12000 initiatives for deputy #{id_diputado} and legis #{id_legislatura}")
    end
  end
  items.each do |item|
    #Fix problem with long descriptions inside returned page
    t = item.text.gsub("\n"," ")
    initiative_types.each_pair do |k,v|
      if t =~ /#{k}\s*:\s+(\d+)/
        tipo = v
        
        iniciativas = $1 ? $1.to_i : nil
        #To be able to link to the initiatives from the front-end
        target_url = (iniciativas && iniciativas > 0) ? createTargetUrl(id_legislatura,id_diputado,tipo) : nil
        data = [id_legislatura,id_diputado,tipo,iniciativas,target_url]
        $output_file.puts CSV::generate_line(data,:encoding => 'utf-8')
        break
      end
    end
  end
end

#To complete relative paths
LOG_LEVEL = "DEBUG"
HOME_SITE = 'http://www.congreso.es'
PREFFIX_URL = 'portal/page/portal/Congreso/PopUpCGI'
QUERY_URL = 'CMD=VERLST&FMT=INITXRDS.fmt&DOCS=1-12000&DOCORDER=FIFO&OPDEF=ADJ'
TARGET_URL = 'CMD=VERLST&FMT=INITXLDC.fmt&DOCS=1-25&DOCORDER=FIFO&OPDEF=ADJ'
#Headers for the output file
HEADERS = ["id_legislatura","id_diputado","id_tipo","iniciativas","url"]   

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
$output_file = File.open("#{OUTPUT_SUBDIR}/#{script_name}.csv", 'w')
$output_file.puts CSV::generate_line(HEADERS,:encoding => 'utf-8')

#Instantiate the mechanize object
agent = Mechanize.new

#Compose url
base_url = "#{HOME_SITE}/#{PREFFIX_URL}?#{QUERY_URL}"
writeLog("ERROR","Test")
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
  base_param = ("10".eql? id_legislatura) ? "IW"+id_legislatura : "IWI"+id_legislatura
  query_param = "D.ACIN3.+y+(#{id_diputado}+ADJ+D).SAUT."
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
  
  #Diputados
  items = doc.css('div.resultados_encontrados li')
  if items.length > 0
    getStats(items,id_legislatura,id_diputado)
  else
    writeLog("WARNING","No results found for #{id_diputado} in legislative period #{id_legislatura}")
  end
  sleep(0.5)
end
$output_file.close
$log_file.close
