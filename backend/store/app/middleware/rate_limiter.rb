class RateLimiter
    def initialize(app)
      @app = app
    end
  
    def call(env)
      request = Rack::Request.new(env)
      
      if api_request?(request) && rate_limited?(request)
        rate_limit_response
      else
        @app.call(env)
      end
    end
  
    private
  
    def api_request?(request)
      request.path.start_with?('/api/')
    end
  
    def rate_limited?(request)
      key = rate_limit_key(request)
      count = Rails.cache.read(key) || 0
      
      if count >= rate_limit
        true
      else
        Rails.cache.write(key, count + 1, expires_in: 1.hour)
        false
      end
    end
  
    def rate_limit_key(request)
      ip = request.ip
      user_id = extract_user_id(request)
      "rate_limit:#{ip}:#{user_id}:#{Time.current.hour}"
    end
  
    def extract_user_id(request)
      # Extract user ID from session or JWT token
      session_data = request.session
      session_data['user_id'] || 'anonymous'
    end
  
    def rate_limit
      1000 # requests per hour
    end
  
    def rate_limit_response
      [429, 
       { 'Content-Type' => 'application/json' },
       [{ error: 'Rate limit exceeded' }.to_json]]
    end
  end