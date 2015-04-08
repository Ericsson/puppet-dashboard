class Filewrite< ActiveRecord::Base
$app_error_file = "#{Rails.root}/log/application_error.log" #This file contains Exception logs

##########To write exception in error log file
def self.write_app_log(e)
        file_use = String.new
        file_use = $app_error_file
        error = String.new
        File.open(file_use, 'a') do |f2|
        error = e
        f2.puts error.strip << "::#{DateTime.now}"
        return true
        end
end


end
