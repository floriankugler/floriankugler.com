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
  blog.layout = "_article_layout"
  blog.summary_separator = /(READMORE)/
  blog.publish_future_dated = !PRODUCTION
end

activate :directory_indexes
activate :gzip

activate :s3_sync do |s3_sync|
  s3_sync.bucket                     = AWS_BUCKET
  s3_sync.aws_access_key_id          = AWS_ACCESS_KEY
  s3_sync.region                     = AWS_REGION
  s3_sync.aws_secret_access_key      = AWS_SECRET
  s3_sync.delete                     = true
  s3_sync.prefer_gzip                = true
end

default_caching_policy max_age:(60 * 60 * 24 * 365)
caching_policy 'text/html', max_age: 0, must_revalidate: true

activate :cloudfront do |cf|
  cf.access_key_id = AWS_ACCESS_KEY
  cf.secret_access_key = AWS_SECRET
  cf.distribution_id = 'E1BDI6N12Y5YNM'
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



redirect '/blog/2013/4/2/the-lack-of-self-knowledge-in-tv-movies', '/2013/03/24/the-lack-of-self-knowledge-in-tv-movies/'
redirect '/blog/2013/4/2/making-autolayout-code-less-painful', '/2013/03/26/making-autolayout-code-less-painful/'
redirect '/blog/2013/4/2/the-concurrent-core-data-stack', '/2013/04/02/the-concurrent-core-data-stack/'
redirect '/blog/2013/4/4/the-economics-of-app-store-pricing', '/2013/04/05/the-economics-of-app-store-pricing/'
redirect '/blog/2013/4/8/a-self-experiment-with-nutritional-ketosis', '/2013/04/08/a-self-experiment-with-nutritional-ketosis/'
redirect '/blog/2013/4/15/interface-builder-ndash-curse-or-convenience', '/2013/04/15/interface-builder-ndash-curse-or-convenience/'
redirect '/blog/2013/4/15/interface-builder-ndash-curse-or-convenience', '/2013/04/22/auto-layout-performance-on-ios/'
redirect '/blog/2013/4/29/concurrent-core-data-stack-performance-shootout', '/2013/04/29/concurrent-core-data-stack-performance-shootout/'
redirect '/blog/2013/4/29/concurrent-core-data-stack-performance-shootout', '/2013/05/13/backstage-with-nested-managed-object-contexts/'
redirect '/blog/2013/5/24/layer-trees-vs-flat-drawing-graphics-performance-across-ios-device-generations', '/2013/05/24/layer-trees-vs-flat-drawing-graphics-performance-across-ios-device-generations/'
redirect '/blog/2013/5/24/layer-trees-vs-flat-drawing-graphics-performance-across-ios-device-generations', '/2013/06/05/uikonf-presentation-app-optimization-with-instruments/'
redirect '/blog/2013/6/5/uikonf-presentation-app-optimization-with-instruments', '/2013/06/07/announcing-objcio/'
redirect '/blog/2013/7/6/objcio-2-concurrent-programming', '/2013/07/08/objcio-2-concurrent-programming/'
redirect '/blog/2013/8/4/upcoming', '/2013/08/04/upcoming/'
redirect '/blog/2013/9/30/worth-less-than-a-cup-of-coffee', '/2013/09/30/worth-less-than-a-cup-of-coffee/'
redirect '/blog/2013/12/20/building-a-mac-app-deckset', '/2013/12/27/building-a-mac-app-deckset/'
redirect '/blog/2013/12/20/building-a-mac-app-deckset', '/2014/02/18/alt-tech-talks-london-one-cannot-not-communicate/'
redirect '/blog/2014/2/18/alt-tech-talks-london-one-cannot-not-communicate', '/2014/04/07/deckset-has-launched/'
redirect '/blog/2014/9/29/functional-programming-in-swift', '/2014/10/03/functional-programming-in-swift/'