# Ruby AkamaiToken

Generate query string parameter for Akamai CDN URLs.

This code was extracted into a module form the Akamai Token v2 command line program.

## Usage

    require 'akamai_token'
	t = AkamaiToken.new(key)
	puts t.create(:start_time => Time.now, :url => '/a/path', ...)
