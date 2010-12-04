class String
  ActionView::Base.sanitized_allowed_tags.replace %w(acronym b strong i em li ul ol h1 h2 h3 h4 h5 h6 blockquote br cite sub sup ins p)
  def sanitize
    ActionController::Base.helpers.sanitize(self)
  end
end