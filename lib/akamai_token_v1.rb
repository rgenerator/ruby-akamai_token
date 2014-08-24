# Implements the v1 token generation algorithm
# for Akamai. 

require 'openssl'

class AkamaiTokenV1
  VERSION = "0.0.1"
  ALGORITHMS =  %w[sha256 md5 sha1].freeze

  def initialize(key, defaults = {}) # keep
    raise ArgumentError, 'missing or invalid key' if !key.is_a?(String) || key.strip.empty?
    @key = key
    @defaults = defaults
  end

  # Implement using v1 algorithm

  def create(config) # keep
    config = @defaults.merge(config)
    config[:key] = @key #key will be the salt parameter
    build_token(config)
  end

  private

  def build_token(confg)
    validate_input(config)

    #initialize variables
    url = config[:url]
    salt = config[:key]
    extract = config[:extract]
    window = config[:window]
    time = config[:time] <= 0 ? Time.now : config[:time]
    
    expires = time + window
    exp_bytes = init_exp_byte(exp_bytes, expires)
    
    md5 = OpenSSL::Digest::MD5.new
    
    first_digest = first_md5_hash(md5, exp_bytes, url, extract, salt)
    temp_bytes = create_temp_bytes(first_digest)
    second_digest = second_md5_hash(md5, salt, temp_bytes)

    token = second_digest.to_s
  end

  def validate_input(config)
    raise ArgumentError, 'You must provide a URL' if config[:url].blank?
    raise ArgumentError, 'You must provide a salt' if config[:key].blank?
    raise ArgumentError, 'You must provide an expiration window' if config[:window].blank?
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
    md5 << extract.bytes unless extract.blank?
    md5 << salt.bytes
    md5.digest
  end

  def create_temp_bytes(first_digest)
    temp_bytes = []
    first_digest.each { |i| temp_bytes.push(i) }
    temp_bytes
  end

  def second_md5_hash(md5, salt, temp_bytes)
    md5.reset
    md5 << salt.bytes
    md5 << tempBytes

    # note, we're calling hexdigest here instead of doing what the 
    # java implementation does, which is convert each character to hexadecimal.
    md5.hexdigest 
  end
end
