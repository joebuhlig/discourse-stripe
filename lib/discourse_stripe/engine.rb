module DiscourseStripe
  class Engine < ::Rails::Engine
    isolate_namespace DiscourseStripe
    config.after_initialize do
  		Discourse::Application.routes.append do
        mount ::DiscourseStripe::Engine, at: "/stripe"
  		end
    end
  end
end
