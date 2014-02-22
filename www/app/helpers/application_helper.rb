module ApplicationHelper

  PATH_TO_IMAGES = "/data/img/"

  def path_to_img(id_diputado, id_legislatura)
    img_name = "#{id_diputado}_#{id_legislatura}.jpg"
    return PATH_TO_IMAGES + img_name;
  end

  def format_bio(text)
    return text.gsub("|", "<br/><br/>").html_safe
  end

end
