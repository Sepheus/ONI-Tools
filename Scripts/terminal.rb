require 'net/http'

class C64Terminal
    REFERER = "http://mjizmja2mjaymju1mzc5ntc3.space/cgi-bin/load-html.py?section=b64&token=57544e6161475244516d6c5a4d6d7870576c686f4d6d4e525054303d"
    URL = "http://mjizmja2mjaymju1mzc5ntc3.space/cgi-bin/b64.py"
    PREFIX =  "65574a786232566965413d3d."

    private_constant :REFERER, :URL, :PREFIX

    def initialize(type, command)
        @type = type.strip
        @command = command.join(" ").strip.upcase
        @uri = URI.parse(URL)
    end

    def send
        send = {
            :try => getCommand,
        }
        fields = sendRequest(send)
    end

    def getCommand
        case @type
        when "0"
            @command
        when "1"
            PREFIX + cycle(1)
        when "2"
            PREFIX + revDec()
        end
    end

    def cycle(n)
        @command
            .bytes
            .map { |byte| byte + n }
            .pack("C*")
            .reverse!
    end

    def revDec()
        @command
            .downcase
            .bytes
            .join
            .tr("0-9", "1-9:")
            .reverse!
    end

    def sendRequest(query)
        @uri.query = URI.encode_www_form(query)

        req = Net::HTTP::Get.new("#{@uri.path}?#{@uri.query}", {
            'Referer' => REFERER,
            'User-Agent'=> "ONI",
        })

        res = Net::HTTP.start(@uri.hostname, @uri.port) {|http|
          http.request(req)
        }

        res.body
    end

    private :sendRequest, :getCommand, :cycle, :revDec

end

type, *command = ARGV
if ARGV.length > 1
    term = C64Terminal.new(type, command)
    puts term.send
else
    puts "Usage: ./terminal <mode> <command>"
end