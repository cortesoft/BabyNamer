Warden::Strategies.add(:password) do
    def valid?
        params['user'] && params['user']['email'] && params['user']['password']
    end

    def authenticate!
        user = User.authenticate(
            params['user']['email'], 
            params['user']['password']
        )
        user.nil? ? fail!('Could not log in') : success!(user, 'Successfully logged in')
    end
end

Warden::Manager.before_failure do |env,opts|
    # Because authentication failure can happen on any request but
    # we handle it only under "post '/auth/unauthenticated'", we need
    # to change request to POST
    env['REQUEST_METHOD'] = 'POST'
    # And we need to do the following to work with  Rack::MethodOverride
    env.each do |key, value|
        env[key]['_method'] = 'post' if key == 'rack.request.form_hash'
    end
end