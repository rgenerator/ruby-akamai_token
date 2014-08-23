# Ruby AkamaiToken

Generate query string parameter for Akamai CDN URLs.

This code was extracted into a module form the Akamai Token v2 command line program.

## Usage

    require 'akamai_token'
	require 'uri'

	t = AkamaiToken.new(key)
	q = t.create(:start_time => Time.now, :url => '/assets/garth.flac')
	uri = URI::HTTPS.build :host => 'rgnrtr.com', :path => '/assets/garth.flac', :query => q

    # Or, set some defaults
    t = AkamaiToken.new(key, defaults)
	# ...
