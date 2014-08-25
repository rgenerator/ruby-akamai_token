# Implements the v1 token generation algorithm
# for Akamai. 

require 'openssl'

class AkamaiTokenV1

  def initialize(key, defaults = {}) # keep
    raise ArgumentError, 'missing or invalid key' if !key.is_a?(String) || key.strip.empty?
    @key = key
    @defaults = defaults
  end

  # Implement using v1 algorithm
  # expects config to have the following keys => :url, :key, :extract, :window, :time. Note, :extract is optional.  
  def create(config) # keep
    config = @defaults.merge(config)
    config[:key] = @key #key will be the salt parameter
    build_token(config)
  end

  private

  def build_token(config)
    validate_input(config)

    #initialize variables
    url = config[:url]
    salt = config[:key]
    extract = config[:extract]
    window = config[:window]
    time = (config[:time] == nil || config[:time] <= 0) ? Time.now.to_i * 1000 : config[:time]
    
    expires = time + window
    exp_bytes = init_exp_byte(expires)
    puts "exp_bytes: #{exp_bytes}"
    
    md5 = OpenSSL::Digest::MD5.new
    
    # hash
    first_digest = first_md5_hash(md5, exp_bytes, url, extract, salt)
    puts "first_digest: #{first_digest}"
    temp_bytes = create_temp_bytes(first_digest)
    puts "temp_bytes: #{temp_bytes}"
    second_digest = second_md5_hash(md5, salt, temp_bytes)
    puts "second_digest: #{second_digest}"

    second_digest
  end

  def validate_input(config)
    raise ArgumentError, 'You must provide a URL' if config[:url] == nil
    raise ArgumentError, 'You must provide a salt' if config[:key] == nil
    raise ArgumentError, 'You must provide an expiration window' if config[:window] == nil
    raise ArgumentError, 'Expiration Window must not be negative' if config[:window] < 0
  end

  def init_exp_byte(expires)
    exp_bytes = []
    exp_bytes.push (expires & 0xff)
    exp_bytes.push ((expires >> 8) & 0xff)
    exp_bytes.push ((expires >> 16) & 0xff)
    exp_bytes.push ((expires >> 24) & 0xff)
    exp_bytes
  end


  def first_md5_hash(md5, exp_bytes, url, extract, salt)
    md5 << exp_bytes
    md5 << url.bytes
    md5 << extract.bytes if (extract && extract.length > 0)
    md5 << salt.bytes
    md5.hexdigest
  end

  def create_temp_bytes(first_digest)
    temp_bytes = []
    first_digest.each_char { |i| temp_bytes.push(i) }
    temp_bytes
  end

  def second_md5_hash(md5, salt, temp_bytes)
    md5.reset
    md5 << salt.bytes
    md5 << temp_bytes
    md5.hexdigest
  end
end
