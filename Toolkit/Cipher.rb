module Cipher
    #There may be problems with padding and whitespace sensitivity as I develop this.
    module Vigenere
        def self.encode(string,key)
            run(string,key,:+)
        end
        def self.decode(string,key)
            run(string,key,:-)
        end
        def self.decode_r(string,key)
            string = string.unpack("C*")
            k = key.unpack("C*")
            s = string.each_with_index.map { |n,i| if n.between?(65,91) || n.between?(97,123) then i end }.compact
            s.length.times { |n| string[s[n]] = (90-((k[n%k.size]- string[s[n]])%26)) }
            string.pack("C*")
        end
        def self.run(string,key,mode)
            string = string.unpack("C*")
            k = key.upcase.unpack("C*")
            s = string.each_with_index.map { |n,i| if n.between?(65,91) || n.between?(97,123) then i end }.compact
            s.length.times.map { |n|
                char = string[s[n]]
                offset = char&0x20
                string[s[n]] = 65+offset+char.send(mode,k[n%k.size].send(mode,-offset))%26
            }
            string.pack("C*")
        end
        private_class_method :run
    end
    module Rot13
        def self.encode(string)
            string.tr('A-Za-z','N-ZA-Mn-za-m')
        end
        def self.decode(string)
            encode(string)
        end
    end
    module Beaufort
        def self.encode(string,key)
            run(string,key)
        end
        def self.decode(string,key)
            run(string,key)
        end
        def self.run(string,key)
            string = string.tr('A-Za-z','ZYXWVUTSRQPONMLKJIHGFEDCBAzyxwvutsrqponmlkjihgfedcba')
            key = key.tr('A-Za-z','ZYXWVUTSRQPONMLKJIHGFEDCBAzyxwvutsrqponmlkjihgfedcba')
            Cipher::Vigenere.decode(string,key)
        end
        private_class_method :run
    end
    module Atbash
        def self.encode(string)
            string.tr('A-Za-z','ZYXWVUTSRQPONMLKJIHGFEDCBAzyxwvutsrqponmlkjihgfedcba')
        end
        def self.decode(string)
            encode(string)
        end
    end
    module Keyword
        def self.encode(string,key)
            trans = (key.upcase.chars.to_a.uniq.join +  "ABCDEFGHIJKLMNOPQRSTUVWXYZ".gsub!(/[#{key.upcase}]/,""))
            trans += trans.downcase
            string.tr('A-Za-z',trans)
        end
        def self.decode(string,key)
            trans = (key.upcase.chars.to_a.uniq.join +  "ABCDEFGHIJKLMNOPQRSTUVWXYZ".gsub!(/[#{key.upcase}]/,""))
            trans += trans.downcase
            string.tr(trans,'A-Za-z')
        end
    end
    module Rail
        def self.encode(string,rails)
            string = string.scan(/[A-Za-z]/)
            if string.length%rails != 0 then string << [*'A'..'Z'].sample end
            string.each_slice(rails).to_a.transpose.join
        end
        def self.decode(string,rails)
            string = string.scan(/[A-Za-z]/)
            string.each_slice(string.length/rails).to_a.transpose.join
        end
    end
    #Needs padding and less input sensitivity.
    module Trifid
        def self.encode(string)
            pad = [["ABC","DEF","GHI"],["JKL","MNO","PQR"],["STU","VWX","YZ"]]
            s = string.upcase.unpack("C*").map { |n| n-65 }
            s.flat_map { |n| [n/9,n%3,n/3%3] }.each_slice(3).to_a.transpose.flatten.each_slice(3).map { |a,b,c| pad[a][c][b] }.join
        end
        def self.decode(string)
            pad = [["ABC","DEF","GHI"],["JKL","MNO","PQR"],["STU","VWX","YZ"]]
            s = string.upcase.unpack("C*").map { |n| n-65 }
            s.flat_map { |n| [n/9,n%3,n/3%3] }.each_slice(13).to_a.transpose.flatten.each_slice(3).map { |a,b,c| pad[a][c][b] }.join
        end
    end

    module Chaocipher
        #http://www.mountainvistasoft.com/chaocipher/ActualChaocipher/Chaocipher-Revealed-Algorithm.pdf
        def self.encode(string)
            run(string,:encode,0,1,1,2)
        end

        def self.decode(string)
            #Swap 'wheels' and their parameters to decode.
            run(string,:decode,1,2,0,1)
        end

        def self.run(string,mode,inc_a,del_a,inc_b,del_b)
            left = ["H","X","U","C","Z","V","A","M","D","S","L","K","P","E","F","J","R","I","G","T","W","O","B","N","Y","Q"]
            right = ["P","T","L","N","B","Q","D","E","O","Y","S","F","A","V","Z","K","G","J","R","I","H","W","X","U","M","C"]
            left, right = (mode == :decode) ? [right,left] : [left,right]
            (0...string.length).map { |n|
                out = string[n]
                char = string[n]
                if !(char =~ /[A-Za-z]/).nil? then
                    index = right.index(char.upcase)
                    out = left[index]
                    out = (char == char.upcase) ? out : out.downcase
                    left.rotate!(index+inc_a)
                    left.insert(13,left.delete_at(del_a))
                    right.rotate!(index+inc_b)
                    right.insert(13,right.delete_at(del_b))
                end
                out
             }.join
        end
        private_class_method :run
    end

end