namespace :uploader do
  desc 'Deploy uploader assets to S3'
  task :deploy => 'assets:environment' do
    config = Rails.application.config.assets
    config.prefix = "/#{ENV['S3_UPLOADER_BUCKET']}/uploader/assets"

    av = ActionView::Base.new(Rails.root.join('app', 'views'))

    html = OpenStruct.new(
      :filename     => 'uploader.html',
      :body         => av.render('uploads/uploader'),
      :content_type => 'text/html'
    )

    files = [
      html,
      asset('uploader.js', 'application/javascript'),
      #asset('uploader.css', 'text/css')
    ]

    files.each do |asset|
      bucket.files.create({
        :key          => "uploader/#{asset.filename}",
        :body         => asset.body,
        :content_type => asset.content_type,
        :public       => true
      })
    end

    puts 'Uploader deployed.'
  end

private

  def bucket
    @bucket ||= fog.directories.new(:key => ENV['S3_UPLOADER_BUCKET'])
  end

  def fog
    require 'fog'
    @fog ||= Fog::Storage.new(
      :provider => 'AWS',
      :aws_access_key_id     => ENV['S3_UPLOADER_ACCESS_KEY'],
      :aws_secret_access_key => ENV['S3_UPLOADER_SECRET_ACCESS_KEY']
    )
  end

  def asset(name, content_type)
    digest = Rails.application.config.assets.digest
    asset = Rails.application.assets[name]
    OpenStruct.new(
      :filename     => "assets/" + (digest ? asset.digest_path : asset.logical_path),
      :body         => asset.to_s,
      :content_type => content_type
    )
  end
end

# Deploy uploader whenever assets are pre-compiled
task 'assets:precompile' do
  Rake::Task['uploader:deploy'].invoke
end