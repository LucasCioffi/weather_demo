Rails.application.routes.draw do
  root "main#home"
  post '/submit_address', to: 'weather#submit_address'
end
