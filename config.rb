###
# Blog settings
###

Time.zone = "Berlin"

PRODUCTION                      = ENV['PRODUCTION']
SITE_NAME                       = 'floriankuger.com'
URL_ROOT                        = 'http://www.floriankugler.com'
AWS_BUCKET                      = PRODUCTION ? 'floriankugler.com' : 'staging.floriankugler.com'
AWS_REGION                      = 'eu-west-1'
AWS_ACCESS_KEY                  = ENV['PERSONAL_AWS_KEY']
AWS_SECRET                      = ENV['PERSONAL_AWS_SECRET']

set :markdown_engine, :redcarpet
set :markdown, :fenced_code_blocks => true, :smartypants => true

activate :blog do |blog|
  blog.sources = "articles/{year}-{month}-{day}-{title}.html"
  blog.layout = "article_layout"
  blog.summary_separator = /(READMORE)/
end

activate :directory_indexes
activate :gzip

activate :s3_sync do |s3_sync|
  s3_sync.bucket                     = AWS_BUCKET
  s3_sync.aws_access_key_id          = AWS_ACCESS_KEY
  s3_sync.region                     = AWS_REGION
  s3_sync.aws_secret_access_key      = AWS_SECRET
  s3_sync.delete                     = false
  s3_sync.prefer_gzip                = true
end

activate :cloudfront do |cf|
  cf.access_key_id = AWS_ACCESS_KEY
  cf.secret_access_key = AWS_SECRET
  cf.distribution_id = 'E1P4GB5IBJ6O1K'
end

activate :s3_redirect do |config|
  config.bucket                = AWS_BUCKET
  config.region                = AWS_REGION
  config.aws_access_key_id     = AWS_ACCESS_KEY
  config.aws_secret_access_key = AWS_SECRET
  config.after_build           = false
end

activate :livereload
activate :syntax


after_s3_sync do |destination_paths|
  invalidate destination_paths[:updated] if PRODUCTION
end



page "/feed.xml", layout: false

set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'

configure :build do
  activate :minify_css
  activate :minify_javascript
  activate :asset_hash
  activate :relative_assets
end
