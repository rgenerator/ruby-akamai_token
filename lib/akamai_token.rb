#
# A version of the Akamai Token v2 command line program -without the CLI.
# Command line arguments are now hash keys.
#

# Copyright (c) 2012, Akamai Technologies, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of Akamai Technologies nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL AKAMAI TECHNOLOGIES BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'cgi'
require 'openssl'

class AkamaiToken
  ALGORITHMS =  %w[sha256 md5 sha1].freeze

  def initialize(key, defaults = {})
    raise ArgumentError, 'missing or invalid key' if !key.is_a?(String) || key.strip.empty?
    @key = key
    @defaults = defaults
  end

  def create(config)
    config = config.merge(:key => @key)
    setup(config)
    build_token(config)
  end

  private
  def setup(config)
    config[:token_name] ||= 'hdnts'
    config[:field_delimiter] ||= "~"

    config[:algo] ||= ALGORITHMS.first
    raise ArgumentError, "algo must be one of #{ALGORITHMS.join(", ")}" unless ALGORITHMS.include?(config[:algo])

    if config[:start_time] != nil
      config[:start_time] = config[:start_time].to_i
    end

    if config[:end_time] != nil
      if config[:end_time].to_i < config[:start_time].to_i
        raise ArgumentError, 'token will have already expired.'
      end
    else
      # Calculate the end time if it hasn't already been given a value.
      if config[:window] != nil
        if config[:start_time] == nil
          config[:end_time] = Time.new.getgm.to_i + config[:window].to_i
        else
          config[:end_time] = config[:start_time].to_i + config[:window].to_i
        end
      else
        raise ArgumentError, 'You must provide an expiration time or a duration window.'
      end
    end

    if config[:key] == nil or config[:key].length < 1
      raise ArgumentError, 'You must provide a secret in order to generate a token'
    end

    if config[:acl] == nil and config[:url] == nil
      raise ArgumentError, 'You must provide a URL or an ACL.'
    end

    if config[:acl] and config[:acl].length > 0 and config[:url] and config[:url].length > 1
      raise ArgumentError, 'You must provide a URL OR an ACL, not both.'
    end
  end

  def build_token(config)
    token_pieces = []

    if config[:ip] != nil
      token_pieces[token_pieces.length] = 'ip=%s' % config[:ip]
    end
    if config[:start_time] != nil
      token_pieces[token_pieces.length] = 'st=%s' % config[:start_time]
    end
    token_pieces[token_pieces.length] = 'exp=%s' % config[:end_time]
    if config[:acl] != nil
      if config[:escape_early]
        token_pieces[token_pieces.length] = 'acl=%s' % CGI::escape(config[:acl]).gsub(/(%..)/) {$1.downcase}
      else
        if config[:escape_early_upper]
          token_pieces[token_pieces.length] = 'acl=%s' % CGI::escape(config[:acl]).gsub(/(%..)/) {$1.upcase}
        else
          token_pieces[token_pieces.length] = 'acl=%s' % config[:acl]
        end
      end
    end

    if config[:session_id] != nil
      token_pieces[token_pieces.length] = 'id=%s' % config[:session_id]
    end

    if config[:payload] != nil
      token_pieces[token_pieces.length] = 'data=%s' % config[:payload]
    end

    new_token = token_pieces.join(config[:field_delimiter])
    if config[:url] and config[:url].length > 0 and config[:acl] == nil
      if config[:escape_early]
        token_pieces[token_pieces.length] = 'url=%s' % CGI::escape(config[:url]).gsub(/(%..)/) {$1.downcase}
      else
        if config[:escape_early_upper]
          token_pieces[token_pieces.length] = 'url=%s' % CGI::escape(config[:url]).gsub(/(%..)/) {$1.upcase}
        else
          token_pieces[token_pieces.length] = 'url=%s' % config[:url]
        end
      end
    end

    if config[:salt] != nil
      token_pieces[token_pieces.length] = 'salt=%s' % config[:salt]
    end

    # Prepare the key
    bin_key = Array(config[:key].gsub(/\s/,'')).pack("H*")

    # Generate the hash
    digest = OpenSSL::Digest.new(config[:algo])
    hmac = OpenSSL::HMAC.new(bin_key, digest)
    hmac.update(token_pieces.join(config[:field_delimiter]))

    # Output the new token
    '%s=%s%shmac=%s' % [config[:token_name], new_token, config[:field_delimiter], hmac.hexdigest()]
  end
end
