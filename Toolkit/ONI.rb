require 'base64'
require 'chunky_png'
require_relative 'Cipher'
#encoding ASCII-8BIT
PNGHEAD = "\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR".force_encoding("ASCII-8BIT")
PNGFOOT = "\x00\x00\x00\x00\x49\x45\x4e\x44\xae\x42\x60\x82".force_encoding("ASCII-8BIT")
ZIPHEAD = "PK\x03\x04".force_encoding("ASCII-8BIT")
RIFFHEAD = "\x52\x49\x46\x46\x24\x08\x1F\x00\x57\x41\x56\x45\x66\x6D\x74\x20".force_encoding("ASCII-8BIT")

class ChunkyPNG::Image
    def to_red_stream
        self.to_rgb_stream.unpack('axx'*(self.to_rgb_stream.length/3)).join
    end
    
    def to_green_stream
        self.to_rgb_stream.unpack('xax'*(self.to_rgb_stream.length/3)).join
    end
    
    def to_blue_stream
        self.to_rgb_stream.unpack('xxa'*(self.to_rgb_stream.length/3)).join
    end
    
    def to_argb_stream
        rgba = self.to_rgba_stream.chars
        (0..rgba.length-1).step(4).map { |n| "#{rgba[n+3]}#{rgba[n]}#{rgba[n+1]}#{rgba[n+2]}" }.join
    end
    
    def get_bytes(stream,type)
        if stream == "alpha" then stream = "alpha_channel" end
        Toolkit.send("get_#{type}_bytes".to_sym, self.send("to_#{stream}_stream".to_sym))
    end
    
    [:get_alpha_lsb_bytes,:get_red_lsb_bytes,:get_green_lsb_bytes,:get_blue_lsb_bytes,:get_alpha_msb_bytes,:get_red_msb_bytes,:get_green_msb_bytes,:get_blue_msb_bytes]
    .each { |method|
        define_method(method) {
            method.to_s.split("_")[2] == "lsb" ? self.get_bytes(method.to_s.split("_")[1],"lsb") : self.get_bytes(method.to_s.split("_")[1],"msb")
        }
    }
    
    
end

class String
    def rev_n
        self.unpack("h*").pack("H*")
    end
    def rev_b
        self.rev_n.reverse
    end
    def decode64
        Base64.decode64(self)
    end
    def encode64
        Base64.strict_encode64(self)
    end
    def reverse64
        Base64.reverse64(self)
    end
    def decrypt(key)
        Toolkit.decrypt(key,self)
    end
    def unmunge(key)
        Toolkit.unmunge(key,self)
    end
    def lookahead(key)
        Toolkit.lookahead(key,self)
    end
    def to_b(mode='b')
        case mode.downcase
        when 'b'
            [self].pack("B*")
        when 'h'
            self.to_bin
        end
    end
    def shift_c(value)
        self.each_byte.map { |n| (n+value)&0xFF }.pack("C*")
    end
    def shift_k(key)
        shift_p(key.bytes)
    end
    def shift_p(key)
        self
            .each_byte
            .each_with_index
            .map { |n, i| ((n - key[i%key.size])&0xFF) }
            .pack("C*")
    end
    def save(filename)
        IO.binwrite(filename,self)
    end
    def interleave(second)
        self.chars.zip(second.chars).join
    end
    def to_bin
        Toolkit.to_bin(self)
    end
    def calendar
        Toolkit.calendar(self)
    end
    
    def unscramble
        Toolkit.unscramble(self)
    end
    
    def unzip
        Toolkit.unzip(self)
    end
    
    def strings(n=4)
        Toolkit.strings(self,n)
    end
    def rot13
        Cipher::Rot13.encode(self)
    end

    def flip
        self.tr("ⱯQƆPƎℲפHIſʞ˥WNOԀQɹS┴∩ΛMX⅄Zɐqɔpǝɟƃɥıɾʞןɯuodbɹsʇnʌʍxʎz","A-Za-z")
    end
    
end

class Array
    def to_b
        [self.join].pack("B*")
    end
end

module Base64
    def self.analyze(b64)
        (Set.new(b64.chars) ^ Set.new([*('A'..'Z'),*('a'..'z'),*('0'..'9')]+"+/?=".chars))
    end
    def self.reverse64(b64)
        Base64.decode64(Base64.encode64(b64).reverse)
    end
end

module ONI
    def self.load(fname)
        IO.binread(fname)
    end
    def self.load_image(fname)
        ChunkyPNG::Image.from_file(fname)
    end
end

module Toolkit

    def self.strings(data,n=4)
        data.scan(/\p{Print}{#{n},}/n)
    end

    def self.unzip(data)
    Zip::Archive.open_buffer(data) { |archive|
        archive.each { |entry|
            entry.read.save(entry.name)
        }
    }
    end

    def self.unscramble(data)
        data.unpack("xa"*(data.length/2)).zip(data.unpack("ax"*(data.length/2))).join
    end

    def self.mergeB64(*args)
        (0..args.length-2).each.inject(args[0].chars) { |n,i| n.zip(args[i+1].chars) }.map { |n| n.flatten.group_by { |e| e }.values.max_by(&:size).first }.join
    end
    def self.to_bin(hexcode)
        hexcode.scan(/[[:xdigit:]]{2}/).map { |n| n.to_i(16) }.pack("C*")
    end
    
    def self.calendar(data)
        deltas = [31,59,90,120,151,181,212,243,273,304,334,365]
        out = ""
        count = data.length
        offset = 31
        n = 1
        until offset >= count
            out << data[offset]
            offset = deltas[n%12]+n+(n/12)*365
            n+=1
        end
        return out
    end
    
    def self.unmunge(key,datanode)
        key = key.unpack("C*").map { |n| n%10 }
        key += key.reverse[0...key.length-1]
        (0...(datanode.length/10)).map { |row| datanode[10*row+key[row % key.size]] }.join
    end
    
    def self.lookahead(key,datanode)
        size = (datanode.length>>1)
        a = b = k = 0
        key = key.unpack("C*")
        s = key.size
        datanode = datanode.unpack("C*")
        output = []
        out_byte = Hash.new(lambda { |b,key_byte| ((b-key_byte)&0xFF) })
        out_byte[1] = lambda { |b,key_byte| ((b+key_byte)&0xFF) }
        size.times { |i|
            k = key[i % s]
            a = datanode[(i<<1)]
            b = datanode[(i<<1)+1]
            output << out_byte[a&1].call(b,k)
        }
        return output.pack("C*")
    end
    def self.decrypt(key,datanode)
        size = (datanode.length>>1)
        a = b = k = d = 0
        s = key.size
        key = key.unpack("C*")
        datanode = datanode.unpack("C*")
        output = []
        size.times { |i|
            k = key[i % s]
            d = datanode[(i<<1)]
            a = k & 1
            b = datanode[(i<<1)+1] & 1
            output << (((d + a)<<1)-b-k) % 256
        }
        return output.pack("C*")
    end
    
    def self.encrypt(key,datanode)
        output = []
        a = b = d = k = 0
        s = key.size
        #(d + k + (!a&b) - (a&b)) >> 1
        first_byte = Hash.new(lambda { |byte,b,key_byte| ((byte+b)+(key_byte)>>1) % 256 })
        first_byte[1] =  lambda { |byte,b,key_byte| ((byte-b)+(key_byte)>>1) % 256 }
        #rand() & 0xFE | (a^b)) << 8
        second_byte = Hash.new(lambda { (Random.rand(256) & 0xFE) })
        second_byte[1] = lambda { (Random.rand(256) | 1) }
        key = key.unpack("C*")
        datanode = datanode.unpack("C*")
        datanode.length.times { |i|
            k = key[i % s]
            d = datanode[i]
            a = k & 1
            b = d & 1
            output << first_byte[a&b].call(d,b,k) << second_byte[a^b].call
        }
        return output.pack("C*")
    end

    def self.combine(*args)
        (0..args.length-2).each.inject(args[0]) { |n,i| n.zip(args[i+1]).map { |x,y| (x.ord|y.ord).chr} }.join
    end
    def self.combine_xor(*args)
        (0..args.length-2).each.inject(args[0]) { |n,i| n.zip(args[i+1]).map { |x,y| (x.ord^y.ord).chr} }.join
    end
    
    def self.freqs(values)
        counts = Hash.new(0)
        values.each { |n| counts[n] += 1 }
        counts.sort_by { |k,v| v }.reverse
    end
    
    def self.get_lsb_bytes(values)
        [values
            .each_byte
            .map { |n| n & 1 }
            .join]
            .pack("B*")
    end
    def self.get_msb_bytes(values)
        [values
            .each_byte
            .map { |n| (n >> 7) & 1 }
            .join]
            .pack("B*")
    end
end

module Morse
    @@m = [".-","-...","-.-.","-..",".","..-.","--.","....","..",".---","-.-",".-..","--","-.","---",".--.","--.-",".-.","...","-","..-","...-",".--","-..-","-.--","--..","-----",".----","..---","...--","....-",".....","-....","--...","---..","----."]
    @@morse = Hash[*(@@m.zip([*('A'..'Z'),*('0'..'9')])).flatten]
    def self.decode(s)
        s.split(" ").map { |n| @@morse[n] }.join
    end
end