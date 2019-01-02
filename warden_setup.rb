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