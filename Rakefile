desc 'Deploy to S3 and invalidate Cloudfront after a Git commit/push'
task :deploy do
  puts '## Syncing to S3 and invalidating Cloudfront...'
  system "bundle exec middleman s3_sync"
  system "bundle exec middleman s3_redirect"
  puts '## Deploy complete.'
end
