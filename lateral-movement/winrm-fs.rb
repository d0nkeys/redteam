#!/usr/bin/env ruby

require 'winrm-fs'
require 'tty-reader'
require 'optparse'

# Author: Alamot, Lupman
# winrm-fs.rb -h 127.0.0.1 -u user -p password
# To upload a file type: UPLOAD local_path remote_path
# e.g.: PS> UPLOAD myfile.txt C:\temp\myfile.txt
# e.g.: PS> DOWNLOAD C:\temp\myfile.txt myfile.txt

reader = TTY::Reader.new

options = {}
OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"

    opts.on('-h', '--host HOST', 'Host address') { |v| options[:host] = v }
    opts.on('-P', '--port PORT', Integer, 'Host port') { |v| options[:port] = v }
    opts.on(nil, '--ssl', 'HTTPS protocol') { |v| options[:ssl] = v }
    opts.on('-u', '--user USERNAME', 'Username') { |v| options[:username] = v }
    opts.on('-p', '--password PASSWORD', 'Password') { |v| options[:password] = v }
    opts.on(nil, '--help', 'Display this screen') do
        puts opts
        exit
    end

end.parse!

if options[:ssl] then
    protocol = "https"
else
    protocol = "http"
end
host = options[:host]
port = options[:port]
if not port then
    if options[:ssl] then
        port = 5986
    else
        port = 5985
    end
end
username = options[:username]
password = options[:password]

if not host then
    puts "No host specified"
    exit
end

if not username then
    username = reader.read_line("Username: ").chomp
end

if not password then
    password = reader.read_line("Password: ", echo: false).chomp
end

#reader = TTY::Reader.new(history_duplicates: true)
reader = TTY::Reader.new(history_duplicates: false)
reader.on(:keyctrl_x) { puts ""; puts "Exiting..."; exit }

conn = WinRM::Connection.new(
    endpoint: "#{protocol}://#{host}:#{port}/wsman",
    transport: :ssl,
    user: username,
    password: password,
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

command = ""

conn.shell(:powershell) do | shell |
    until command == "exit\n" do
        begin
            output = shell.run("-join($id,'PS ',$(whoami),'@',$env:computername,' ',$pwd,'> ')")
            command = reader.read_line(output.output.chomp)

            if command.start_with?('UPLOAD ') then
                upload_command = command.tokenize
                src = upload_command[1]                
                dest = upload_command[2]

                if not dest then
                    dest = upload_command[1].split('/')[-1]
                end
                if not dest.index ':\\' then
                    output = shell.run("-join($pwd)")
                    dest = output.output.chomp.strip() + "\\" + dest
                end

                puts("Uploading " + src + " to " + dest)
                file_manager.upload(src, dest) do | bytes_copied, total_bytes, local_path, remote_path |
                    puts("#{bytes_copied} bytes of #{total_bytes} bytes copied")
                end
                command = "echo OK`n"
            end

            if command.start_with?('DOWNLOAD ') then
                download_command = command.tokenize
                
                src = download_command[1]
                if not src.index ':\\' then
                    output = shell.run("-join($pwd)")
                    src = output.output.chomp.strip() + "\\" + src
                end

                dest = download_command[2]
                if not dest then
                    dest = download_command[1].split('\\')[-1]
                end

                puts("Downloading " + src + " to " + dest)
                file_manager.download(src, dest) do | bytes_copied, total_bytes, remote_path, local_path |
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
