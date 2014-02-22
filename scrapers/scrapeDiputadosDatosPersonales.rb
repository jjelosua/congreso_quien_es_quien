# encoding: utf-8
#Libraries needed for the program
require 'fileutils'
require 'mechanize'
require 'csv'
# To correctly transform the case of special spanish caracters
require 'unicode_utils'

def getAndDownloadPicture(agent,doc) 
  picture_src = doc.css('div#datos_diputado img')[0]["src"]
  picture_src =~ /diputados\/(.*)$/
  filename = $1 ? $1 : nil
  unless File.exists?("#{OUTPUT_SUBDIR}/img/#{filename}")
    begin
      url = "#{HOME_SITE}#{picture_src}"
      agent.get(url).save!("#{OUTPUT_SUBDIR}/img/#{filename}")
    rescue Mechanize::ResponseCodeError => the_error
      $log_file.puts("#{url}: Got a bad status code #{the_error.response_code}")
    end
  end
  return filename
end

def getGender(doc) 
  header_info = doc.css('div#curriculum div.texto_dip')[0]
  items = header_info.css("div.dip_rojo")
  gender = nil
  items.each do |item|
    if item.text =~ /Diputado por/
      gender = 'H'
      break
    elsif item.text =~ /Diputada por/
      gender = 'M'
      break
    end
  end
  return gender
end

def getBioData(cv) 
  items = cv.css("li")
  bio = ""
  items.each do |item|
    if (item.css("div").length == 0 && item.css("a").length == 0)
      bio << "#{item.text.gsub(/\s+/, " ")}|"
    end
  end
  return bio.gsub!(/[|]+$/,"")
end

def getDates(cv) 
  fec_alta, fec_baja = nil
  items = cv.css('div.dip_rojo')
  items.each do |item|
    if item.text =~ /Fecha alta:\s*(\d{2})\/(\d{2})\/(\d{4})/
      fec_alta = "#{$3}-#{$2}-#{$1}" unless $1.nil?
    elsif item.text  =~ /Causó baja el\s*(\d{2})\/(\d{2})\/(\d{4})/
      fec_baja = "#{$3}-#{$2}-#{$1}" unless $1.nil?
    end
  end
  return fec_alta, fec_baja
end

def saveContactsData(cv,id_legislatura,id_diputado) 
  contact_types = {"email"=> 0,"twitter"=>1,"facebook"=>2,"other"=>9}
  
  links = cv.css('div.webperso_dip a')
  if links.length > 0 
    links.each do |link|
      href = link["href"]
      if href =~/mailto:(.*)/
        contactType = 0
        contact = $1 ? $1 : nil
      elsif href =~ /twitter.com\//
        contactType = 1
        contact = href
      elsif href =~ /facebook.com\//
        contactType = 2
        contact = href
      else
        contactType = 9
        contact = href
      end
      $contacts_file.puts CSV::generate_line([id_legislatura,id_diputado,contactType,contact],:encoding => 'utf-8')
    end
  end
end

def saveDeclarationsData(cv,id_legislatura,id_diputado) 
  declaration_type = {"bienes"=> 0,"actividades"=>1}
  
  links = cv.css('li.regact_dip a')
  if links.length > 0 
    links.each do |link|
      href = link["href"]
      if href =~/docbienes/
        declarationType = 0
        declaration = "#{HOME_SITE}#{href}"
      elsif href =~ /docinte\//
        declarationType = 1
        declaration = "#{HOME_SITE}#{href}"
      end
      $declarations_file.puts CSV::generate_line([id_legislatura,id_diputado,declarationType,declaration],:encoding => 'utf-8')
    end
  end
end

#To complete relative paths
HOME_SITE = 'http://www.congreso.es'
PREFFIX_URL = 'portal/page/portal/Congreso/Congreso/Diputados/DipGrupParl'
QUERY_URL = '_piref73_1333475_73_1333472_1333472.next_page=/wc/composicionGrupo'
#Headers for the output file
HEADERS = ["id_legislatura","id_diputado","foto_id","gender","bio","fec_alta","fec_baja"]
HEADERS_CONTACTS = ["id_legislatura","id_diputado","id_tipoContacto","contacto"]
HEADERS_DECLARATIONS = ["id_legislatura","id_diputado","id_tipoDeclaracion","declaracion"]   

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

#Contacts output file
$contacts_file = File.open("#{OUTPUT_SUBDIR}/#{script_name}_contactos.csv", 'w')
$contacts_file.puts CSV::generate_line(HEADERS_CONTACTS,:encoding => 'utf-8')

#Declarations output file
$declarations_file = File.open("#{OUTPUT_SUBDIR}/#{script_name}_declaraciones.csv", 'w')
$declarations_file.puts CSV::generate_line(HEADERS_DECLARATIONS,:encoding => 'utf-8')

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
  puts "processing deputy: #{id_diputado} for legislative period: #{id_legislatura}"
  #Get page
  begin
    page = agent.get(url)
  rescue Mechanize::ResponseCodeError => the_error
    $log_file.puts("#{url}: Got a bad status code #{the_error.response_code}")
  end
  
  #Get the nokogiri parsed document
  doc = page.parser
  
  #download the picture and get id
  picture_id = getAndDownloadPicture(agent,doc)
  gender = getGender(doc)
  
  #Diputados
  textos = doc.css('div#curriculum div.texto_dip')
  if textos.length > 0
    cv = textos[1]
    bio = getBioData(cv)
    fec_alta, fec_baja = getDates(cv)
    saveContactsData(cv,id_legislatura,id_diputado)
    saveDeclarationsData(cv,id_legislatura,id_diputado)
  end
  output_file.puts CSV::generate_line([id_legislatura,id_diputado,picture_id,gender,bio,fec_alta,fec_baja],:encoding => 'utf-8')
  sleep(0.5)
end
output_file.close
$contacts_file.close
$declarations_file.close
$log_file.close
