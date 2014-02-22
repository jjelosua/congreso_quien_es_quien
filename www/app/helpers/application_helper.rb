module ApplicationHelper

  PATH_TO_IMAGES = "/data/img/"

  def path_to_img(foto)
    img_name = "#{foto}"
    return PATH_TO_IMAGES + img_name;
  end

  def format_bio(text)
    return text.gsub("|", "<br/><br/>").html_safe
  end

end
