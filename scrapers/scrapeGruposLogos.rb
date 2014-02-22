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

def getGroupLogo(agent,doc) 
  logo_grupo = doc.css('div#datos_diputado p.logo_grupo')[1]
  logo = logo_grupo.css("img")
  if logo.length > 0
    logo_src = logo[0]["src"]
    logo_src =~ /.*\/(.*)/
    filename = $1 ? $1 : nil
    puts filename
    unless File.exists?("#{OUTPUT_SUBDIR}/logos/#{filename}")
      begin
        url = "#{HOME_SITE}#{logo_src}"
        agent.get(url).save!("#{OUTPUT_SUBDIR}/logos/#{filename}")
      rescue Mechanize::ResponseCodeError => the_error
        writeLog("ERROR","Got a bad status code #{the_error.response_code} for #{url}")
      end
    end
  end
end

#To complete relative paths
HOME_SITE = 'http://www.congreso.es'
#Logging level
LOG_LEVEL = "DEBUG"
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

#Instantiate the mechanize object
agent = Mechanize.new

count = 0
CSV.foreach("#{INPUT_SUBDIR}/#{INPUT_FILE}") do |row|
  id,idDiputado,idLegislatura,url = row
  
  #Skip header
  if count == 0
    count += 1
    next
  end
  legis = idLegislatura.to_i
  if legis > 5 && legis < 10 
    begin
      puts url
      page = agent.get(url)
    rescue Mechanize::ResponseCodeError => the_error
      writeLog("ERROR","Got a bad status code #{the_error.response_code} for #{url}")
    end
    #Get the nokogiri parsed document
    doc = page.parser
    getGroupLogo(agent,doc)
    sleep(0.5)
  end
end
$log_file.close
