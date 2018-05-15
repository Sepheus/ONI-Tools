require '../Cipher.rb'

SAMPLE = "One two three, four five SIX SEVEN EIGHT! 12345"
KEY = "AmazingTestKey"
SAMPLE.freeze
KEY.freeze

shared_examples "Cipher" do
    describe "#encode" do
        it "is supported" do
            expect(cipher.respond_to? :encode).to be_true
        end
    end
    describe "#decode" do
        it "is supported" do
            expect(cipher.respond_to? :decode).to be_true
        end
    end
end

shared_examples "Alpha Cipher" do
    describe "encode/decode" do
        it "correctly encodes and decodes plaintext" do
            cipher.decode(cipher.encode(SAMPLE,KEY),KEY).should eq(SAMPLE)
        end
    end
end

shared_examples "Keyless Cipher" do
    describe "encode/decode" do
        it "correctly encodes and decodes plaintext" do
            cipher.decode(cipher.encode(SAMPLE)).should eq(SAMPLE)
        end
    end
end


Cipher.constants.each { |cipher|
    describe Cipher.const_get(cipher) do
        it_behaves_like "Cipher" do
            let(:cipher) { Cipher.const_get(cipher) }
        end
    end
}


[Cipher::Vigenere,Cipher::Keyword,Cipher::Beaufort].each { |cipher|
    describe cipher do
        it_behaves_like "Alpha Cipher" do
            let(:cipher) { described_class }
        end
    end
}

[Cipher::Atbash,Cipher::Rot13,Cipher::Chaocipher].each { |cipher|
    describe cipher do
        it_behaves_like "Keyless Cipher" do
            let(:cipher) { described_class }
        end
    end
}