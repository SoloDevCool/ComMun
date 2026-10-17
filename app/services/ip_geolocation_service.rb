class IpGeolocationService
  CACHE_EXPIRY = 7.days
  API_ENDPOINT = "http://ip-api.com/json/%{ip}?lang=zh-CN&fields=status,message,country,regionName,city,isp"

  def self.lookup(ip_address)
    return default_result if ip_address.blank? || private_ip?(ip_address)

    cache_key = "ip_geo_#{ip_address}"

    if (cached = Rails.cache.read(cache_key))
      return cached
    end

    result = fetch_from_api(ip_address)
    Rails.cache.write(cache_key, result, expires_in: CACHE_EXPIRY)
    result
  rescue StandardError => e
    Rails.logger.error "IP Geolocation error: #{e.message}"
    default_result
  end

  class << self
    private

    def fetch_from_api(ip)
      uri = URI(format(API_ENDPOINT, ip: ip))
      response = Net::HTTP.get(uri, "Content-Type" => "application/json")
      data = JSON.parse(response)

      if data["status"] == "success"
        {
          country: data["country"].to_s,
          province: data["regionName"].to_s,
          city: data["city"].to_s,
          isp: data["isp"].to_s
        }
      else
        default_result
      end
    rescue JSON::ParserError, Net::HTTPError
      default_result
    end

    def private_ip?(ip)
      IPAddr.new(ip).private?
    rescue IPAddr::InvalidAddressError
      true
    end

    def default_result
      { country: "", province: "", city: "", isp: "" }
    end
  end
end
