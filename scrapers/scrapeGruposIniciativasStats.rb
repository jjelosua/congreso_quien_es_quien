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
=begin
  TODO buscar los datos de solicitudes de comparecencias tipo 105 DOCs del 1-2000
=end
def createTargetUrl(id_legislatura,id_grupo,nombre,tipo)
  #Compose url
  base_url = "#{HOME_SITE}/#{PREFFIX_URL}?#{TARGET_URL}"
  base_param = ("10".eql? id_legislatura) ? "IW"+id_legislatura : "IWI"+id_legislatura
  query_param = "#{tipo}.ACIN2.+y+%28#{id_grupo}+ADJ+G%29.SAUT."
  desc_param = URI::encode(nombre)
  url = "#{base_url}&BASE=#{base_param}&QUERY=#{query_param}&DES1=#{desc_param}"
  return url
   
end

def getStats(list,id_legislatura,id_grupo,nombre)  
  #The stats dashboard is wrong crossing 104 and 105 type
  initiative_types = {"Confianza Parlamentaria"=> 101,
                   "Función Legislativa"=>102,
                   "Interpelaciones"=>105,
                   "Solicitud de comparecencia"=>105,
                   "Proposiciones no de Ley"=>107,
                   "Mociones"=>108,
                   "Solicitudes de creación de comisiones, subcomisiones y ponencias"=>109,
                   "Reglamento del Congreso"=>110,
                   "Relaciones con otros órganos e instituciones públicas"=>111}                
  
  
  #Check if total is greater than expected
  if list.css('li').last.text =~ /Total\s*:\s+(\d+)/
    total = $1 ? $1.to_i : nil
    if total > 5000 
      puts "leches: #{total}"
      writeLog("WARNING","More than 5000 initiatives for group #{id_grupo} and legis #{id_legislatura}")
    end
  end
  
  items = list.css("li,span.segundoNivel") 
  items.each do |item|
    #The information is not on the first level
    if (item.css("span").length == 0)
      next
    end
    #Fix problem with long descriptions inside returned page
    t = item.text.gsub("\n"," ")
    initiative_types.each_pair do |k,v|
      if t =~ /#{k}\s*:\s+(\d+)/
        tipo = v 
        iniciativas = $1 ? $1.to_i : nil
        #To be able to link to the initiatives from the front-end 
        target_url = (iniciativas && iniciativas > 0) ? createTargetUrl(id_legislatura,id_grupo,nombre,tipo) : nil
        data = [id_legislatura,id_grupo,tipo,iniciativas,target_url]
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
TARGET_URL = 'CMD=VERLST&FMT=INITXLGC.fmt&DOCS=1-25&DOCORDER=FIFO&OPDEF=ADJ'
QUERY_URL = 'CMD=VERLST&FMT=INITXRGS.fmt&DOCS=1-5000&DOCORDER=FIFO&OPDEF=ADJ'


#Headers for the output file
HEADERS = ["id_legislatura","id_grupo","id_tipo","iniciativas","url"]   

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
  id_legislatura,id_grupo,nombre = row
  #Skip header
  if count == 0
    count += 1
    next
  end
  
  writeLog("DEBUG","Processing group: #{id_grupo} for legislative period: #{id_legislatura}")
  #Create url
  base_param = ("10".eql? id_legislatura) ? "IW"+id_legislatura : "IWI"+id_legislatura
  query_param = "G.ACIN2.+y+(#{id_grupo}+ADJ+G).SAUT."
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
  
  #Grupos
  list = doc.css('div.resultados_encontrados ul')
  if list.length > 0
    getStats(list,id_legislatura,id_grupo,nombre)
    
    #We need to handle initiative type 104 manually since it is not returned by the stats dashboard
    target = createTargetUrl(id_legislatura,id_grupo,nombre,104).gsub!(/DOCS=1-25/,"DOCS=1-2000")
    #Get page
    begin
      page = agent.get(target)
    rescue Mechanize::ResponseCodeError => the_error
      writeLog("ERROR","Got a bad status code #{the_error.response_code} for #{url}")
    end
    results = page.parser.css("div.numero_paginas")
    results.text =~ /1\s*al\s*(\d+)/
    iniciativas = $1 ? $1.to_i : 0
    target_url = (iniciativas && iniciativas > 0) ? target : nil
    data = [id_legislatura,id_grupo,104,iniciativas,target_url]
    $output_file.puts CSV::generate_line(data,:encoding => 'utf-8')    
  else
    writeLog("WARNING","No results found for #{id_grupo} in legislative period #{id_legislatura}")
  end
  sleep(0.5)
end
$output_file.close
$log_file.close
