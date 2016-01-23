if selected?(:paperclip)
  gather_gem('paperclip', '~> 4.3')

  gsub_file "config/environments/production.rb", /^end$/o do |_match|
    %{

  # Paperclip support for S3
  config.paperclip_defaults = {
    :storage => :s3,
    :s3_credentials => {
      :bucket => ENV['AWS_BUCKET']
    }
  }
end}
  end

  append_to_file '.env.example', 'AWS_BUCKET='
  append_to_file '.env', 'AWS_BUCKET='

end
