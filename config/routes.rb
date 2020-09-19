DiscourseStripe::Engine.routes.draw do
  post '/webhook' => "webhook#stripe"
end
