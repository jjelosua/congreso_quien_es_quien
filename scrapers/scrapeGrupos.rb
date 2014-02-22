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
QUERY_URL = '_piref73_1333477_73_1333472_1333472.next_page=/wc/cambioLegislatura'
#Headers for the output file
HEADERS = ["id_legislatura","id_grupo","nombre"] 

#Create the folders where the data and logs will be stored
#Create the folders where the data and logs will be stored
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
url = "#{HOME_SITE}/#{PREFFIX_URL}?#{QUERY_URL}"

#Get the cookie from the main page
for id in 0..10
  puts "Processing legislative period: #{id}"
  
  begin
    params = {'idLegislatura' => id}
    page = agent.post(url,params)
  rescue Mechanize::ResponseCodeError => the_error
    log_file.puts("#{url}: Got a bad status code #{the_error.response_code}")
  end
  
  #Get the nokogiri parsed document
  doc = page.parser
  
  #nombre
  links = doc.css("div.listado_1 li a")
  links.each do |link|
    href = link["href"]
    href =~/idGrupo=(\d+)/
    id_grupo = $1 ? $1 : nil
    nombre = link.text.strip
    puts nombre
    output_file.puts CSV::generate_line([id,id_grupo,nombre],:encoding => 'utf-8')
  end
  sleep(0.5)
end
output_file.close
log_file.close
