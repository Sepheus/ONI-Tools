require 'net/http'

class GFight

    REFERER = "http://mjizmja2mjaymju1mzc5ntc3.space/cgi-bin/load-html.py?section=gfight&token=3131304130313041313131413031303041303130304131313141464130303130413030413131304130303030413141304130313041464130303031414641313131313141303130313031413131303030"
    URL = "http://mjizmja2mjaymju1mzc5ntc3.space/cgi-bin/gfight.py"
    MAX_REQUESTS = 500
    BASEVALUE = 20

    private_constant :REFERER, :URL, :MAX_REQUESTS, :BASEVALUE

    def initialize(opName)
        @opName = opName.strip.upcase
        @codes = Hash.new(0)
        @uri = URI.parse(URL)
        @loggedIn = false
        @matchId = nil
        @level = 1
        @score = 0
        @drops = 0
        @booms = 0
        @cookies = 0
        @sec3s = 0
        @scoreNeeded = BASEVALUE
    end


    def login
        login = {
            :state => "login",
            :opId => "#{@opName}"
        }
        fields = sendRequest(login)
        @loggedIn = fields.length == 2 ? true : false
    end

    def start
        if @loggedIn
            start = {
                :state => "start",
                :opId => "#{@opName}"
            }
            fields = sendRequest(start)
            @matchId = fields.length == 2 ? fields.last : nil
        end
    end

    def fight
        if @loggedIn && !@matchId.nil?
            requestCount = 0
            until @codes.length == 3 || requestCount > MAX_REQUESTS
                getDrop()
                requestCount += 1
                @score += BASEVALUE
                checkLevel
            end
        end
    end

    def getDrop
        fight = { 
            :state => "getdrop", 
            :gameId => @matchId, 
            :opId => @opName, 
            :level => @level
        }

        state, roll, code = sendRequest(fight)

        !code.nil?? @codes[code] += 1 : nil
        case roll
            when "3"
                @sec3s += 1
            when "2"
                @booms += 1
            when "1"
                @cookies += 1
            else
                @drops += 1
        end
    end

    def checkLevel
        if @score >= @scoreNeeded
            @level += 1
            @scoreNeeded += (@level * BASEVALUE)
        end
    end

    def end
        if @loggedIn && !@matchId.nil?
            finish = {
                :state => "end",
                :gameId => @matchId,
                :level => @level,
                :score => @score,
                :cookies => @cookies,
                :sec3s => @sec3s,
                :superBooms => @booms,
                :grolloDrops => @drops
            }

            sendRequest(finish)
        end
    end

    def codes
        @codes.keys
    end

    def operative
        @opName
    end

    def loggedIn?
        @loggedIn
    end

    def matchId
        @matchId
    end

    def displayScore
        if @loggedIn
            puts "Congratulations OP!"
            puts "#{@opName} Report Card:"
            puts "Level: #{@level.to_s.rjust(10)}"
            puts "Score: #{@score.to_s.rjust(10)}"
            puts "Cookies: #{@cookies.to_s.rjust(8)}"
            puts "Powerups: #{@sec3s.to_s.rjust(7)}"
            puts "SUPERBOOMS: #{@booms.to_s.rjust(5)}"
            puts "Trash: #{@drops.to_s.rjust(10)}"
            puts "Rating:        A+"
        end
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

        res.body.strip.split("|")
    end

    private :sendRequest, :checkLevel, :getDrop

end

op, *bin = ARGV
if ARGV.length == 1
    gfight = GFight.new(op)
    puts "Logging in #{gfight.operative}..."
    gfight.login
    if gfight.loggedIn?
        gfight.start
        puts "Starting new match! (#{gfight.matchId})"
        puts "Fighting the good fight... please wait."
        gfight.fight
        gfight.end
        gfight.displayScore
        if gfight.codes.length == 3
            puts "Here's what you won! #{gfight.codes.join(", ")}"
        else
            puts "You found #{gfight.codes.join(", ")} but you might be missing something."
        end
    else
        puts "I don't know who #{gfight.operative} is."
    end
else
    puts "Usage: ./gfight <opname>"
end