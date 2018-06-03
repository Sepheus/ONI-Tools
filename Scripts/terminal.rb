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
        p send
        fields = sendRequest(send)
    end

    def getCommand
        case @type
        when "0"
            PREFIX + @command
        when "1"
            PREFIX + cycle(1)
        when "2"
            PREFIX + revDec()
        when "3"
            PREFIX + term3()
        when "4"
            PREFIX + term4()
        when "5"
            PREFIX + term5()
        when "6"
            term6()
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

    def term3()
        @command
            .downcase
            .bytes
            .reverse
            .each_with_index
            .group_by { |_,i| i.even? }
            .map { |k,v| 
                k ? v.reverse! : v
                v.map { |h,t| h }
            }
            .join
            .tr("0-9", "1-9:")
            .reverse!
    end

    def term4()
        @command
            .downcase
            .bytes
            .values_at(
                *(
                    [*@command.length/2...@command.length]
                    .reverse
                    .zip([*0...@command.length/2])
                )
                .flatten
                .compact
            )
            .join
            .tr("0-9", "1-9:")
            .reverse!
    end

    def term5() 
        @command = @command
            .downcase
            .tr("a-z","abcdefghijklmnopqrstuvwxyz".reverse)
            .tr(" .", "\xBB\xAD".force_encoding("ASCII-8BIT"))
        term4()
    end

    def term6()
        @command = "OVERFLOW_OFF[print {push 0x93f203ee90a0-0x93fff0000001,0xce2551,1,0,0,1}]"
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

    private :sendRequest, :getCommand, :cycle, :revDec, :term3

end

type, *command = ARGV
if ARGV.length > 1
    term = C64Terminal.new(type, command)
    puts term.send
else
    puts "Usage: ./terminal <mode> <command>"
end