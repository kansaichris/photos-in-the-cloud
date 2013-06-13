require 'openssl'
require 'base64'

###############################################################################
# Utility Methods
###############################################################################

# Get the current time in the following format
# Mon, 01 Jan 2001 00:00:00 +0900
def current_time
    # %a - Abbreviated weekday name (e.g. "Mon")
    # %d - Day of the month, zero-padded (01..31)
    # %b - Abbreviated month name (e.g. "Jan")
    # %Y - Year with century (can be negative, 4 digits at least)
    # %H - Hour of the day, 24-hour clock, zero-padded (00..23)
    # %M - Minute of the hour (00..59)
    # %S - Second of the minute (00..60)
    # %z - Time zone as hour and minute offset from UTC (e.g. +0900)
    Time.now.strftime("%a, %d %b %Y %H:%M:%S %z")
end

# Calculate the Base64-encoded SHA-1 HMAC signature of a key and string
def hmac_signature(key, string_to_sign)
    digest = OpenSSL::HMAC.digest('sha1', key, string_to_sign)
    signature = Base64.encode64(digest)
end

# Calculate the authentication header for an Amazon Web Services request
def auth_header(access_key_id, secret_access_key, string_to_sign)
    signature = hmac_signature(secret_access_key, string_to_sign)
    header = "AWS #{access_key_id}:#{signature}"
end

