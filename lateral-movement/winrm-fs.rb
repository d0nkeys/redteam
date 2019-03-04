#!/usr/bin/env ruby

require 'winrm-fs'
require 'tty-reader'

# Author: Alamot, Lupman
# To upload a file type: UPLOAD local_path remote_path
# e.g.: PS> UPLOAD myfile.txt C:\temp\myfile.txt
# e.g.: PS> DOWNLOAD C:\temp\myfile.txt myfile.txt

conn = WinRM::Connection.new( 
    endpoint: 'http://localhost:5985/wsman',
    user: 'user',
    password: 'password',
    #transport: :ssl,
    :no_ssl_peer_verification => true
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

reader = TTY::Reader.new(history_duplicates: true)

reader.on(:keyctrl_x) { puts ""; puts "Exiting..."; exit }

command=""

conn.shell(:powershell) do | shell |
    until command == "exit\n" do
        begin
            output = shell.run("-join($id,'PS ',$(whoami),'@',$env:computername,' ',$pwd,'> ')")
            command = reader.read_line(output.output.chomp)

            if command.start_with?('UPLOAD') then
                upload_command = command.tokenize
                dest = upload_command[2]
                if not dest then
                    dest = upload_command[1].split('/')[-1]
                    output = shell.run("-join($pwd)")
                    dest = output.output.chomp.strip() + "\\" + dest
                end
                puts("Uploading " + upload_command[1] + " to " + dest)
                file_manager.upload(upload_command[1], dest) do | bytes_copied, total_bytes, local_path, remote_path |
                    puts("#{bytes_copied} bytes of #{total_bytes} bytes copied")
                end
                command = "echo OK`n"
            end

            if command.start_with?('DOWNLOAD') then
                download_command = command.tokenize
                dest = download_command[2]
                if not dest then
                    dest = download_command[1].split('\\')[-1]
                end
                puts("Downloading " + download_command[1] + " to " + dest)
                file_manager.download(download_command[1], dest) do | bytes_copied, total_bytes, remote_path, local_path |
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
