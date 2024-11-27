
module Fastlane
  module Actions
    class SlackUploadAction < Action
      def self.run(params)
        require 'net/http'
        require 'json'
        require 'uri'
        require 'faraday'
        
        title = params[:title]
        filepath = params[:file_path]
        filename = params[:file_name]
        initialComment = params[:initial_comment]

        if params[:file_type].to_s.empty?
          filetype = File.extname(filepath)[1..-1] # Remove '.' from the file extension
        else
          filetype = params[:file_type]
        end

        begin
          # Get upload URL
          uri = URI("https://slack.com/api/files.getUploadURLExternal")
          uri.query = URI.encode_www_form([["filename", filename], ["length", File.size(filepath)]])
          req = Net::HTTP::Post.new(uri)
          req['Authorization'] = "Bearer #{params[:slack_api_token]}"
          req['Content-Type'] = "application/json"

          response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
            http.request(req)
          end

          data = JSON.parse(response.body)
          if not data['ok']
            raise "Error getting upload URL: #{data['error']}"
          end
          file_id = data['file_id']
          upload_url = data['upload_url']

          # Upload file
          req = Faraday.post(upload_url) do |req|
            req.body = Faraday::UploadIO.new(filepath, filetype)
          end

          if response.code.to_i != 200
            raise "Error uploading file: #{response.body}"
          end

          UI.success("Uploaded file to Slack: id=#{file_id}")

          # Complete upload
          files = JSON.generate([{id: file_id, title: title}])

          UI.message("Completing upload: #{files}")

          uri = URI("https://slack.com/api/files.completeUploadExternal")
          uri.query = URI.encode_www_form({
            files: files,
            channel_id: params[:channel],
            initial_comment: initialComment
          })
          req = Net::HTTP::Post.new(uri)
          req['Authorization'] = "Bearer #{params[:slack_api_token]}"

          UI.success("Completing upload: #{uri}")

          response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
            http.request(req)
          end

          data = JSON.parse(response.body)
    
          if not data['ok']
            raise "Error completing upload: #{data['error']}"
          end
        rescue => exception
          UI.error("Exception: #{exception}")
          UI.error("Backtrace:\n\t#{exception.backtrace.join("\n\t")}")
        ensure
          UI.success('Successfully sent file to Slack')
        end
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :slack_api_token,
                                       env_name: "SLACK_API_TOKEN",
                                       sensitive: true,
                                       description: "Slack API token"),
          FastlaneCore::ConfigItem.new(key: :title,
                                       env_name: "SLACK_UPLOAD_TITLE",
                                       description: "Title of the file",
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :channel,
                                       env_name: "SLACK_UPLOAD_CHANNEL",
                                       description: "Channel ID",
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :file_path,
                                       env_name: "SLACK_UPLOAD_FILE_PATH",
                                       description: "Path to the file",
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :file_type,
                                       env_name: "SLACK_UPLOAD_FILE_TYPE",
                                       description: "A file type identifier",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :file_name,
                                       env_name: "SLACK_UPLOAD_FILE_NAME",
                                       description: "Filename of file",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :initial_comment,
                                       env_name: "SLACK_UPLOAD_INITIAL_COMMENT",
                                       description: "Initial comment to add to file",
                                       optional: true)                  
        ]
      end

      def self.is_supported?(platform)
        true
      end

      def self.description
        'Uploads given file to Slack'
      end

      def self.authors
        ['Dawid Cieslak', 'Zvonimir Rudinski']
      end

      def self.example_code
        [
          'slack_upload(
            title: "screenshots.zip",
            channel: "channel_id",
            file_path: "./screenshots.zip"
          )',
          'slack_upload(
            slack_api_token: "xyz", 
            title: "screenshots.zip",
            channel: "channel_id",
            file_path: "./screenshots.zip",
            file_type: "zip",                        # Optional, type can be recognized from file path,
            file_name: "screen_shots.zip",           # Optional, name can be recognized from file path,
            initial_comment: "Enjoy!"                # Optional
            )'
        ]
      end
    end
  end
end
