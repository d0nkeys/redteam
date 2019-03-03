#!/usr/bin/env ruby

require 'winrm-fs'

# Author: Alamot, Lupman
# To upload a file type: UPLOAD local_path remote_path
# e.g.: PS> UPLOAD myfile.txt C:\temp\myfile.txt
# e.g.: PS> DOWNLOAD C:\temp\myfile.txt myfile.txt

conn = WinRM::Connection.new(
  endpoint: 'http://localhost:5985/wsman',
  user: 'user',
  password: 'password'
)

file_manager = WinRM::FS::FileManager.new(conn)

class String
    def tokenize
        self.
            split(/\s(?=(?:[^'"]|'[^']*'|"[^"]*")*$)/).
            select {|s| not s.empty? }.
            map {|s| s.gsub(/(^ +)|( +$)|(^["']+)|(["']+$)/,'')}
    end
end

command=""

conn.shell(:powershell) do | shell |
    until command == "exit\n" do
        begin
            output = shell.run("-join($id,'PS ',$(whoami),'@',$env:computername,' ',$pwd,'> ')")
            print(output.output.chomp)
            command = gets

            if command.start_with?('UPLOAD') then
                upload_command = command.tokenize
                puts("Uploading " + upload_command[1] + " to " + (upload_command[2] || upload_command[1]))
                file_manager.upload(upload_command[1], upload_command[2] || upload_command[1]) do | bytes_copied, total_bytes, local_path, remote_path |
                    puts("#{bytes_copied} bytes of #{total_bytes} bytes copied")
                end
                command = "echo OK`n"
            end

            if command.start_with?('DOWNLOAD') then
                download_command = command.tokenize
                puts("Downloading " + download_command[1] + " to " + (download_command[2] || download_command[1]))
                file_manager.download(download_command[1], download_command[2] || download_command[1]) do | bytes_copied, total_bytes, remote_path, local_path |
                    puts("#{bytes_copied} bytes of #{total_bytes} bytes copied")
                end
                command = "echo OK`n"
            end

            output = shell.run(command) do | stdout, stderr |
                if stdout != nil
                    STDOUT.write stdout.rstrip + "\n"
                end
                if stderr != nil
                    STDOUT.write stderr.rstrip + "\n"
                end
            end
        rescue => e
            puts e
        end
    end    
    puts("Exiting with code #{output.exitcode}")
end
