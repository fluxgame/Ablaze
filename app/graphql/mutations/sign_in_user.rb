class Mutations::SignInUser < GraphQL::Function
  argument :email, !Types::AuthProviderEmailInput

  # define what this field will return
  type Types::AuthenticateType

  # resolve the field's response
  def call(obj, args, ctx)
    puts "email: " + args[:email] + ", password: " + input[:password]
    input = args[:email]
    return unless input

    user = User.find_by(email: input[:email])
    return unless user
    return unless user.authenticate(input[:password])

    user.create_new_auth_token
  end
end